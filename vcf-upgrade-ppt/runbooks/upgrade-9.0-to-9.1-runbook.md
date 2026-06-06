# Runbook：VCF 9.0.x → 9.1 升級流程

> 輔助手冊，不取代官方流程。以官方 **VCF 9.1 Upgrade Planning Tool**、**9.1.0.0 Release Notes**（<https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes.html>）與升級文件為準。

## 9.1 重點變更

- 新增 **VCF Management Services**（整合 Fleet + SDDC lifecycle）與專屬 **License Server**。
- VCF Operations / Operations for logs/networks / Automation / Identity Broker 的生命週期管理於升 9.1 時轉移至 Management Services。
- 9.0 的 vIDB 外部多節點 appliance cluster 於 9.1 直接遷入 Management Services，原獨立 VM 可關機除役。
- **fleet 層與管理網域強制升級**；WLD 可延後為 Day-N。

## 前置

1. 跑 **VCF 9.1 Upgrade Planning Tool** 確認目標與流程。
2. 全面盤點（目標版本填 9.1.0）：
   ```powershell
   ./scripts/precheck/Invoke-VCFUpgradePrecheck.ps1 -Environment <env> -TargetVersion 9.1.0
   ```
3. **關鍵第一步**：將 **VCF Identity Broker 從 NSX overlay segment 遷移到管理網路**，否則升級會失敗（依官方步驟操作）。
4. 備份 SDDC / Management 元件並驗證可還原。
5. 建立升級前 baseline：
   ```powershell
   ./scripts/healthcheck/Compare-VCFState.ps1 -Environment <env> -Mode Capture -SnapshotPath ./before91-<env>.json
   ```

## 升級步驟

1. **VCF Operations / Fleet → Management Services 轉移**：依官方於 VCF Operations 介面執行；生命週期管理轉移至 Management Services。
2. **fleet 層與管理網域強制升級**：
   ```powershell
   ./scripts/change/Invoke-VCFStagedUpgrade.ps1 -Environment <env> -DomainId <mgmt-domain-id> -Stage ALL `
       -BundleMap @{SDDC='b1';NSX='b2';VCENTER='b3';ESX='b4'}
   ```
   每階段後做健檢 gate（同 5.2→9.0 runbook）。
3. **WLD（Day-N）**：管理網域穩定後，再排程升級各 Workload Domain；可分批。
4. **vIDB 除役**：9.0 外部多節點 vIDB cluster 遷入 Management Services 後，依官方確認可關機原獨立 VM。

## 各環境注意事項

- **UAT / TEST**：先演練 Identity Broker 遷移與 Management Services 轉移，這是 9.1 最容易出錯處。
- **PROD**：變更腳本加 `-ForceProdChange -ChangeTicket <單號>`；管理網域先升、WLD 排 Day-N；逐階段 gate。

## 驗證

```powershell
./scripts/healthcheck/Compare-VCFState.ps1 -Environment <env> -Mode Compare -SnapshotPath ./before91-<env>.json
```
確認管理網域元件版本到 9.1、Identity Broker 於管理網路正常、Management Services 接管生命週期。

## 回退檢查點

同 5.2→9.0：無完整 rollback。以元件層級備份為回復點，階段失敗即停、依官方 KB 處理，不跳階段。特別注意 Identity Broker 遷移若未完成不得續行升級。
