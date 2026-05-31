# HCX 部署 Runbook (Site Pairing → Profile → Service Mesh)

建立 HCX 遷移所需的傳輸基礎：站台配對、Compute/Network Profile、Service Mesh。
本 runbook 對應腳本：
- `scripts/change/New-HcxServiceMesh.ps1` (Service Mesh)
- `scripts/change/New-HcxNetworkExtension.ps1` (L2 延伸)
- `scripts/healthcheck/Get-HcxHealth.ps1` (驗證)

> 安全分級：**Service Mesh / NE 建立屬「變更」**，一律經 `Invoke-VCFChange` 護欄。
> 先在 UAT/TEST 驗證，PROD 需 `-ForceProdChange` + `-ChangeTicket` + 備份確認。

## 0. 前置

1. 安裝 `VMware.PowerCLI`、`Microsoft.PowerShell.SecretManagement`。
2. 設定 `lib/environments.psd1` (含 `HcxManager` / `vCenter` / `Tier`)。
3. 建立憑證：`Set-Secret -Name vcf-uat -Secret (Get-Credential)`。
4. 匯入框架：
   ```powershell
   Import-Module ./lib/VCFGuardrails.psm1 -Force
   Import-Module ./lib/VCFConnect.psm1   -Force
   ```
5. 確認來源 / 目的端 HCX Manager 版本 (建議 4.11.4) 與 vSphere/NSX 相容性。
   - WAN Optimization 已於 4.11.4 移除，升級前需先移除該服務。

## 1. Site Pairing (站台配對)

Site pairing 建立管理 / 認證 / 編排通道。可於 HCX UI 或 API 建立。
- API：`POST /hybridity/api/admin/global/config/sitePairings` (以官方 API 文件為準)。
- 驗證：執行 `Get-HcxHealth.ps1 -Environment <env>`，確認 `Site Pairing` 段列出遠端站台。

## 2. Compute / Network Profile

- Compute Profile：定義 HCX appliance 要部署到哪個 cluster / datastore / resource pool 與啟用哪些服務 (IX / NE)。
- Network Profile：定義 Management / Uplink / vMotion / Replication 網路與 IP pool。
- 兩端各自建立 (來源 Connector 與目的 Cloud)。建議於 UI 完成，記下名稱供 Service Mesh 引用。

## 3. 建立 Service Mesh

```powershell
# UAT
./scripts/change/New-HcxServiceMesh.ps1 -Environment uat -MeshName SM-UAT `
    -RemoteSiteName cloud-uat -SourceComputeProfile CP-Src -RemoteComputeProfile CP-Dst

# PROD (需提權 + 變更單號)
./scripts/change/New-HcxServiceMesh.ps1 -Environment prod -MeshName SM-PROD `
    -RemoteSiteName cloud-prod -SourceComputeProfile CP-Src -RemoteComputeProfile CP-Dst `
    -ForceProdChange -ChangeTicket CHG0001234
```
會先列出 dry-run 預覽，確認後才提交。建立後 HCX 會在兩端部署 IX/NE appliance 並建立 tunnel。

## 4. 驗證

```powershell
./scripts/healthcheck/Get-HcxHealth.ps1 -Environment uat
```
確認：
- Service Mesh 出現於清單。
- IX / NE appliance `status=UP`、`tunnel=UP`。
- (如已建 NE) Network Extension 狀態正常。

## 5. (選用) 建立 Network Extension

```powershell
./scripts/change/New-HcxNetworkExtension.ps1 -Environment uat -NetworkName 'app-seg' `
    -ServiceMeshName SM-UAT -DestinationT1 T1-App -GatewayCidr '10.10.10.1/24' -EnableMON
```
- MON 啟用後，SDDC 端 T1 以 /32 啟用閘道並加靜態路由 (不向 on-prem 通告)；請先規劃 MON Route Policy。

## 各環境注意事項

| 環境 | 注意 |
|------|------|
| UAT | 自由驗證流程與 API body 結構，確認 appliance/tunnel 起得來。 |
| TEST | `RequireBackup=$true`；建立前確認可回復。驗證跨站頻寬與相容性。 |
| PROD | 預設 `AllowChange=$false`；需 `-ForceProdChange` + `-ChangeTicket` + 備份確認 + 環境名稱二次確認。安排維運窗，避開尖峰。 |

## 回退

- Service Mesh / NE 在遷移開始前皆可刪除 (UI 或對應 DELETE API)，刪除 NE 前確認其上無延伸中的生產流量。
- 刪除為破壞性操作，請以 `Invoke-VCFChange -Impact Destructive` 包裝 (PROD 需輸入 DESTROY)。

## 權威來源

- HCX User Guide 4.11: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11.html
- Configuring the HCX Service Mesh: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/vmware-hcx-user-guide-4-11/configuring-and-managing-the-hcx-interconnect/configuring-the-hcx-service-mesh.html
- About HCX MON: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/about-hcx-mobility-optimized-networking.html
