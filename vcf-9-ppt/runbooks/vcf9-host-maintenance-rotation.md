# Runbook：VCF 9 ESX Host 維護模式輪替

> 安全分級：**Change**。會改動環境，全程透過 `Invoke-VCFChange` 護欄。
> 對應腳本：`scripts/change/Set-Vcf9HostMaintenance.ps1`
> 前置健檢：`scripts/healthcheck/Get-Vcf9Health.ps1`

## 目的
為 ESX host 進行硬體維護、韌體更新或 patch 前後，安全地讓 host 逐台進入/離開維護模式，並正確處理 vSAN 資料疏散，確保叢集容量與冗餘不被破壞。

## 前置條件
1. 完成 `lib/` 設定與 SecretManagement 憑證 (見日常健檢 runbook 前置)。
2. 先跑健檢確認叢集為 green、vSAN 容量有足夠 slack、HA/DRS 正常：
   ```powershell
   ./vcf-9-ppt/scripts/healthcheck/Get-Vcf9Health.ps1 -Environment <env>
   ```
3. 確認叢集可容忍少一台 host (FTT 與容量)；一次只輪替一台。
4. PROD：已開立變更單號、已通知、已在維護視窗。

## 步驟 (逐台)
1. **進入維護模式**：
   - UAT/TEST：
     ```powershell
     ./vcf-9-ppt/scripts/change/Set-Vcf9HostMaintenance.ps1 -Environment test -VMHostName esx01.corp.local -Action Enter
     ```
   - PROD：
     ```powershell
     ./vcf-9-ppt/scripts/change/Set-Vcf9HostMaintenance.ps1 -Environment prod -VMHostName esx01.corp.local `
        -Action Enter -ForceProdChange -ChangeTicket CHG0012345
     ```
   - 預設 vSAN 疏散策略 `EnsureAccessibility`；若要清空該 host 上所有 vSAN 元件改用 `-VsanDataMigration Full`。
2. 確認腳本回報狀態為 `Maintenance` 後，執行硬體/韌體維護工作。
3. **離開維護模式**：
   ```powershell
   ./vcf-9-ppt/scripts/change/Set-Vcf9HostMaintenance.ps1 -Environment <env> -VMHostName esx01.corp.local -Action Exit [-ForceProdChange -ChangeTicket ...]
   ```
4. 跑健檢確認該 host 回到 Connected、vSAN 重新同步完成 (resync = 0) 後，再處理下一台。

## 驗證
- host ConnectionState = Maintenance (進入後) / Connected (離開後)。
- vSAN resync 物件數歸零、OverallHealth = green。
- 叢集 HA 重新保護完成，無新增告警。

## 各環境注意事項
- **UAT**：可用來練習與驗證 vSAN 疏散行為。
- **TEST**：以與 PROD 相同步驟演練，記錄每台疏散耗時供 PROD 估時。
- **PROD**：一次一台；必須 `-ForceProdChange -ChangeTicket`；`Invoke-VCFChange` 會要求備份確認與環境名二次確認。嚴禁同時對同叢集多台進入維護模式。

## 回退
- 若進入維護模式後維護工作取消：直接以 `-Action Exit` 讓 host 退出維護模式，DRS 會重新平衡。
- 若 host 進入維護模式逾時：勿強制斷線；至 vCenter 檢查 vSAN 疏散進度，必要時改 `EnsureAccessibility` 重試。
- 若離開維護模式後 host 異常：保持其於維護模式，開案排查，避免承載工作負載。
