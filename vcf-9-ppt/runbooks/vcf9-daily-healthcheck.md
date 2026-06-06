# Runbook：VCF 9 日常健檢 (唯讀)

> 安全分級：**ReadOnly**。本 runbook 全程不改動環境，可直接於 PROD 執行。
> 對應腳本：
> - `scripts/healthcheck/Get-Vcf9Health.ps1` (PowerCLI + REST 綜合健檢)
> - `scripts/healthcheck/Get-Vcf9PasswordCertExpiry.ps1` (密碼/憑證到期)
> - `scripts/healthcheck/vcf9_fleet_inventory.py` (純 REST 盤點，無 PowerCLI 環境用)

## 目的
每日/每班次快速確認 VCF 9 Fleet 健康：Domain/Cluster/Host 狀態、ESX 版本、vSAN 健康、NSX 狀態、系統告警、密碼/憑證到期，及早發現問題。

## 前置條件
1. 已安裝共用框架 `lib/`，並由 `environments.example.psd1` 複製出 `environments.psd1` 填入 uat/test/prod。
2. 已將各環境 PSCredential 存入 SecretManagement：
   `Set-Secret -Name vcf-prod -Secret (Get-Credential)`
3. PowerShell 7+、`VMware.PowerCLI`、`Microsoft.PowerShell.SecretManagement`。
4. 跳板機可連到 SDDC Manager (443)、vCenter (443)、NSX (443)。
5. (Python 版) `pip install requests`，並以環境變數 `VCF_USER` / `VCF_PASS` 注入帳密。

## 步驟
1. 進入 repo 根目錄。
2. 執行綜合健檢 (以 prod 為例)：
   ```powershell
   ./vcf-9-ppt/scripts/healthcheck/Get-Vcf9Health.ps1 -Environment prod -OutputJson ./health-prod.json
   ```
3. 執行密碼/憑證到期檢查：
   ```powershell
   ./vcf-9-ppt/scripts/healthcheck/Get-Vcf9PasswordCertExpiry.ps1 -Environment prod -WarnDays 45
   ```
4. (無 PowerCLI 環境，純 REST 盤點)：
   ```bash
   export VCF_USER='administrator@vsphere.local'; export VCF_PASS='********'
   python3 vcf-9/scripts/healthcheck/vcf9_fleet_inventory.py --sddc sddc.corp.local --json fleet.json
   ```

## 驗證 (健康判準)
- Domain/Cluster/Host 狀態皆為 ACTIVE/healthy，無 host 處於非預期維護模式。
- ESX 版本與 BOM 相符；無版本漂移。
- vSAN OverallHealth = green。
- NSX overall_status = STABLE。
- 無 CRITICAL/WARNING 告警 (或皆為已知並追蹤中)。
- 憑證距到期 ≥ WarnDays；密碼輪替時間在政策範圍內。

## 各環境注意事項
- **UAT**：可較寬鬆，主要驗證腳本與連線正常。
- **TEST**：作為 PROD 演練，建議與 PROD 相同頻率執行以累積基準值。
- **PROD**：唯讀，可任意執行。若帳密/憑證接近到期，請開變更單並走對應 change 流程 (本 runbook 不處理變更)。

## 回退
本 runbook 為唯讀，無需回退。若腳本連線失敗，檢查 SecretManagement 祕密、網路與憑證信任，再重試。
