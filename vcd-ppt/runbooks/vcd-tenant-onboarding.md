# Runbook：新租戶 Onboarding (建 Org + OrgVDC + Edge)

為新客戶 / BU 在 VMware Cloud Director 建立完整租戶骨架：Organization → Org VDC (配額)
→ Edge Gateway (南北向網路)。

> 本 runbook 含「會改動環境」的步驟，**一律透過 `Invoke-VCFChange` 執行**：先 dry-run
> 預覽、UAT/TEST 單次確認、PROD 二次確認 + 變更單號 + 備份確認。**務必先在 UAT 全流程演練**。

## 1. 前置條件

- 已完成 `vcd-healthcheck.md` 之前置 (SecretManagement 憑證、`environments.psd1` 含 `Vcd` 欄位)。
- Provider 帳號具 System 管理員權限。
- 已確認來源 **Provider VDC (PVDC)** 名稱與其 **storage profile** 名稱 (由 `Get-VcdHealth.ps1` 或 Provider Portal 取得)。
- 已和需求方確認租戶配額：CPU(MHz)、記憶體(MB)、儲存(MB)、配置模型 (AllocationPool / PAYG / Reservation / Flex)。
- Edge Gateway 需先確認外部網路 / Tier-0 / IP Spaces 規劃 (NSX 側)。

## 2. 步驟

依序執行；每步都會先顯示 dry-run 預覽，確認無誤再回答 `y` (PROD 另需二次確認)。

1. 建立 Organization：
   ```powershell
   ./vcd-ppt/scripts/change/New-VcdOrganization.ps1 -Environment uat `
       -OrgName acme -DisplayName 'ACME Corp' -Description '新客戶 ACME'
   ```
2. 建立 Org VDC (含配額)：
   ```powershell
   ./vcd-ppt/scripts/change/New-VcdOrgVdc.ps1 -Environment uat `
       -OrgName acme -VdcName acme-vdc01 -ProviderVdc PVDC-Gold `
       -AllocationModel AllocationPool `
       -CpuLimitMhz 20000 -MemoryLimitMb 65536 `
       -StorageProfile 'Gold' -StorageLimitMb 512000
   ```
3. 建立 Edge Gateway：
   - Edge Gateway 之建立高度依賴 NSX (Tier-0 / external network / IP Spaces) 與貴環境 API 版本的
     `edgeGateways` schema，差異大。本 skill **不提供寫死的 Edge 建立腳本**，請依下列其一執行，
     並務必沿用 `Invoke-VCFChange` 包裝：
     - 以官方 OpenAPI `POST /cloudapi/1.0.0/edgeGateways` (body 內含 `orgVdc`、`gatewayBacking` /
       `edgeGatewayUplinks`)，schema 以官方文件為準：
       https://developer.broadcom.com/xapis/vmware-cloud-director-openapi/latest/cloudapi/1.0.0/edgeGateways/
     - 或先以 Provider Portal 建立 Edge，再用本 skill 健檢驗證。
   - 範例 (將 Edge 建立包進框架；NSX/uplink 參數需依環境填入)：
     ```powershell
     Import-Module ./lib/VCFGuardrails.psm1 -Force
     Import-Module ./lib/VCFConnect.psm1   -Force
     Import-Module ./vcd-ppt/scripts/lib/VCDApi.psm1 -Force
     $env  = Get-VCFEnvironment -Name uat
     $conn = Connect-VcdApi -Environment $env
     $body = @{ name='acme-edge01'; orgVdc=@{ name='acme-vdc01' } # ... uplinks 依官方 schema 補齊
              }
     Invoke-VCFChange -Environment $env -Description "建立 Edge Gateway acme-edge01" -Impact Change `
         -Preview { "POST /cloudapi/1.0.0/edgeGateways"; ($body|ConvertTo-Json -Depth 8) } `
         -Action  { Invoke-VcdApi -Conn $conn -Path '/cloudapi/1.0.0/edgeGateways' -Method Post -Body $body }
     ```
4. (選用) 分享共用 catalog 給新租戶 — 見 `vcd-catalog-distribution.md`。

## 3. 各環境注意事項

| 環境 | 注意事項 |
| --- | --- |
| UAT  | **務必先在此完整演練全流程**，確認 PVDC/storage profile 名稱、配額單位 (MHz/MB) 與 Edge schema 正確。 |
| TEST | 以接近 PROD 的命名/配額再演練一次；確認 OrgVDC schema (`vdcsparams`) 在該 API 版本可被接受。 |
| PROD | 需 `-ForceProdChange` 與 `-ChangeTicket <單號>`；框架會要求確認備份、完整輸入環境名稱二次確認。建議在維護視窗執行，逐步 (Org→OrgVDC→Edge) 並於每步後以健檢驗證。 |

## 4. 驗證

```powershell
./vcd-ppt/scripts/healthcheck/Get-VcdHealth.ps1 -Environment uat
```
- 新 Org 出現於清單且 `isEnabled=true`。
- 新 OrgVDC 出現、配置模型/配額正確、`isEnabled=true`。
- 新 Edge Gateway 出現且 `status` 正常。
- 租戶測試帳號可登入 Tenant Portal 並見到資源。

## 5. 回退

> 刪除為破壞性操作；如需移除，請以 `Invoke-VCFChange -Impact Destructive` 包裝
> (PROD 需輸入 `DESTROY` 二次確認)。**本專案規範：永不主動移除任何檔案/環境物件，刪除一律人工複核。**

- Edge Gateway：`DELETE /cloudapi/1.0.0/edgeGateways/{id}` (以官方 API 文件為準)。
- Org VDC：先停用再刪除 (`DELETE /api/admin/vdc/{id}`，以官方 API 文件為準)。
- Organization：先 `Set-VcdOrganizationState.ps1 -Enable:$false` 停用，再經人工複核刪除。
- 回退順序與建立相反：Edge → OrgVDC → Org。每步後以健檢確認。

## 6. 權威來源

- VCD API Programming Guide for Service Providers 10.6：
  https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/-vcloud-api-programming-guide-for-service-providers-10-6.html
- Create Org (OpenAPI)：
  https://developer.broadcom.com/xapis/vmware-cloud-director-openapi/latest/cloudapi/1.0.0/orgs/post/
- Edge Gateways (OpenAPI)：
  https://developer.broadcom.com/xapis/vmware-cloud-director-openapi/latest/cloudapi/1.0.0/edgeGateways/
