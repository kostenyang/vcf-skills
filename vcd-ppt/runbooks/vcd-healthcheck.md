# Runbook：VCD 健檢 (唯讀)

對 VMware Cloud Director 進行例行唯讀健檢：cell 狀態、API 版本、Provider/Org/OrgVDC
清單與配額用量、Edge Gateway 狀態、catalog 同步狀態、租戶資源用量報表。

> 本 runbook 全程「唯讀」，只發 GET，不改動環境。可在任何環境 (含 PROD) 安全執行。

## 1. 前置條件

- PowerShell 7+ (`pwsh`)，已安裝模組：`Microsoft.PowerShell.SecretManagement`、`Microsoft.PowerShell.SecretStore`。
- Python 3.8+ 並 `pip install requests` (僅租戶用量報表 `vcd_tenant_usage_report.py` 需要)。
- 已依 `lib/README.md` 將各環境憑證放入 SecretManagement：
  ```powershell
  Set-Secret -Name vcd-uat  -Secret (Get-Credential)   # 使用者填 administrator (Provider/System 管理員)
  Set-Secret -Name vcd-test -Secret (Get-Credential)
  Set-Secret -Name vcd-prod -Secret (Get-Credential)
  ```
- `lib/environments.psd1` 已由 `environments.example.psd1` 複製並填入；**每個環境需新增 `Vcd` 欄位** (VCD Cell / Load Balancer FQDN) 與對應 `CredentialName`：
  ```powershell
  uat = @{
      Tier = 'UAT'; Vcd = 'vcd-uat.lab.local'; CredentialName = 'vcd-uat'
      # ... 其餘 vCenter/Nsx 等欄位照舊
  }
  ```
- 對 VCD Cell/LB 的 443 連線可達；TLS 憑證受信 (內部 CA 不齊時腳本以 `-SkipCertificateCheck` 處理)。

## 2. 步驟

1. 主健檢 (cell/版本/Org/OrgVDC/Edge)：
   ```powershell
   ./vcd-ppt/scripts/healthcheck/Get-VcdHealth.ps1 -Environment uat
   # 需要存檔供比對 / 報告：
   ./vcd-ppt/scripts/healthcheck/Get-VcdHealth.ps1 -Environment prod -OutputJson ./vcd-prod-health.json
   ```
2. Catalog 同步狀態：
   ```powershell
   ./vcd-ppt/scripts/healthcheck/Get-VcdCatalogSyncStatus.ps1 -Environment uat
   ```
3. 租戶資源用量報表 (Python / REST)：
   ```powershell
   $c = Get-Secret -Name vcd-uat
   $env:VCD_USER = $c.UserName
   $env:VCD_PASS = $c.GetNetworkCredential().Password
   python3 ./vcd-ppt/scripts/healthcheck/vcd_tenant_usage_report.py --host vcd-uat.lab.local --tier UAT --csv usage-uat.csv
   Remove-Item Env:VCD_PASS   # 用完即清除
   ```

## 3. 各環境注意事項

| 環境 | 注意事項 |
| --- | --- |
| UAT  | 可自由反覆執行；先在此驗證 API 版本協商 (若預設 38.1 不支援，先 `GET /api/versions` 查可用版本，再用 `-ApiVersion`)。 |
| TEST | 同 UAT；可作為 PROD 前的最後排練，比對輸出格式。 |
| PROD | 健檢唯讀、可安全執行，但仍建議於低峰時段並避免大量翻頁造成 cell 負載；輸出 JSON 保存作為變更前後對照基準 (before/after)。 |

## 4. 驗證

- `Get-VcdHealth.ps1` 結尾顯示「健檢完成 (唯讀)」且 Org/OrgVDC/Edge 數量與 CMDB 預期相符。
- Catalog 健檢顯示「所有 catalog item 皆為就緒狀態」，或明確列出非就緒項目。
- 租戶用量 CSV 可開啟，欄位齊全 (若 `cpu_used_*` 等欄位空白，代表該 API 版本模型欄位不同，請對照官方 OpenAPI orgVdc 模型)。

## 5. 回退

- 本 runbook 無變更動作，**無需回退**。
- 若腳本連線失敗：確認 `Vcd` FQDN、SecretManagement 憑證 (Provider 帳號需具 System 權限)、API 版本、網路/TLS。

## 6. 權威來源

- VCD API Programming Guide for Service Providers 10.6：
  https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/-vcloud-api-programming-guide-for-service-providers-10-6.html
- Create a Session (Container API)：
  https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/-vcloud-api-programming-guide-for-service-providers-10-6/exploring-the-cloud-api/create-a-session-container-api.html
- VMware Cloud Director OpenAPI (edgeGateways / orgs / orgVdcs)：
  https://developer.broadcom.com/xapis/vmware-cloud-director-openapi/latest/
