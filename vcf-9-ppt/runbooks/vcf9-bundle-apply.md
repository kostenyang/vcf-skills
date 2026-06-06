# Runbook：VCF 9 LCM Bundle 下載與套用流程

> 安全分級：下載 = **Change**；套用 = **Destructive**。全程透過 `Invoke-VCFChange` 護欄。
> 對應腳本：
> - 前置盤點：`scripts/precheck/Invoke-Vcf9UpgradePrecheck.ps1`
> - 觸發/輪詢：`scripts/change/Invoke-Vcf9BundleLifecycle.ps1`
> - 維護模式：`scripts/change/Set-Vcf9HostMaintenance.ps1` (套用過程由 LCM 自動處理，必要時手動輔助)

> 重要：本流程腳本僅『觸發與輪詢』官方 LCM 任務，不取代官方升級程序。元件升級順序與相容性一律以 Broadcom 官方升級指南與 Bill of Materials 為準。

## 目的
標準化 VCF 9 的 bundle 下載與套用 (patch/升級) 操作，確保先盤點、先下載、先在低風險環境演練，PROD 才在維護視窗套用。

## 前置條件
1. `lib/` 與 SecretManagement 已設定。
2. SDDC Manager 已綁定線上或離線 depot (depot 設定屬另一流程)。
3. 已閱讀目標版本官方 Release Notes / BOM / 升級指南，確認升級路徑受支援。
4. 已完成備份/快照 (SDDC Manager、vCenter、NSX Manager)。

## 步驟
### 階段 1 — Precheck (唯讀)
```powershell
./vcf-9-ppt/scripts/precheck/Invoke-Vcf9UpgradePrecheck.ps1 -Environment <env> -TargetVersion '9.1.0.0'
```
確認：可用 upgradable 含目標版本、所有 cluster 為 vLCM image-based、無 CRITICAL/WARNING 告警、vSAN 容量有緩衝。

### 階段 2 — 下載 Bundle (Change)
取得目標 `bundleId` (由 precheck/`/v1/bundles` 或 SDDC Manager UI)，然後：
```powershell
./vcf-9-ppt/scripts/change/Invoke-Vcf9BundleLifecycle.ps1 -Environment <env> -Mode Download -BundleId <bundleId>
```
腳本會觸發下載並輪詢至 COMPLETED。

### 階段 3 — 套用 (Destructive，先 TEST 後 PROD)
```powershell
# 先在 TEST 演練
./vcf-9-ppt/scripts/change/Invoke-Vcf9BundleLifecycle.ps1 -Environment test -Mode Apply `
   -BundleId <bundleId> -ResourceType DOMAIN -ResourceId <domainId>

# PROD (維護視窗內)
./vcf-9-ppt/scripts/change/Invoke-Vcf9BundleLifecycle.ps1 -Environment prod -Mode Apply `
   -BundleId <bundleId> -ResourceType DOMAIN -ResourceId <domainId> `
   -ForceProdChange -ChangeTicket CHG0012345
```
腳本會建立升級任務並輪詢；過程中 LCM 會自動輪替 host 進入/離開維護模式。

### 階段 4 — 套用後驗證
```powershell
./vcf-9-ppt/scripts/healthcheck/Get-Vcf9Health.ps1 -Environment <env>
```

## 驗證
- 升級任務 status = COMPLETED/SUCCESSFUL。
- 各元件版本符合目標 BOM；所有 host Connected、版本一致。
- vSAN green、NSX STABLE、無新增 CRITICAL 告警。

## 各環境注意事項
- **UAT**：用於驗證 bundleId、depot 連線與腳本流程。
- **TEST**：套用前完整演練，記錄耗時與遇到的問題；TEST 通過才排 PROD。
- **PROD**：必須 `-ForceProdChange -ChangeTicket`，`Invoke-VCFChange` 會要求備份確認、環境名二次確認，套用 (Destructive) 另需輸入 `DESTROY`。務必在維護視窗，並一次只升一個 domain。

## 回退
- 下載階段失敗：可重試下載；不影響執行環境。
- 套用失敗：**不要**自行回滾元件。依官方升級指南的 retry/resume 機制，從 SDDC Manager / VCF Operations 重試失敗任務；無法前進時開 Broadcom 支援案，並依事前備份/快照評估還原 (還原為高風險，需另開變更)。
- 套用前務必確保備份/快照可用且已驗證可還原，這是唯一可靠的回退底線。
