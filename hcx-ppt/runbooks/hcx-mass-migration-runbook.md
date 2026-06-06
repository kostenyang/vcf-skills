# HCX 大規模遷移 Runbook (Wave 波次規劃 / Cutover / 回退)

以 Bulk / RAV 進行大批量、低停機遷移的標準作業。對應腳本：
- `scripts/precheck/Get-HcxMigrationPrecheck.ps1` (遷移前盤點)
- `scripts/change/Submit-HcxMigration.ps1` (提交 / 監控 / cutover)
- `scripts/healthcheck/Get-HcxHealth.ps1` (進度與 tunnel)

> 安全分級：**提交遷移屬大規模「變更」**，一律經 `Invoke-VCFChange`。
> RAV/Bulk 規模大，**PROD 嚴守切換窗、分波次、護欄**。先在 UAT/TEST 完整演練。

## 遷移類型選型

- 量大又要零停機 → **RAV** (並行複製 + 序列 vMotion 切換)。
- 量大、可接受切換短停、可排程 → **Bulk** (vSphere Replication，切換時重啟)。

## 0. 前置

1. 完成 `hcx-deployment-runbook.md` (site pairing / Service Mesh / 必要 NE 已 UP)。
2. 匯入框架並設定 `environments.psd1` 與 SecretManagement 憑證。
3. 確認 IX/NE appliance 數與頻寬 (單 IX ~1.6 Gbps、單流 ~1 Gbps)。

## 1. 遷移前盤點 (precheck, 唯讀)

```powershell
./scripts/precheck/Get-HcxMigrationPrecheck.ps1 -Environment uat -VMNamePattern 'app-*' -ConcurrencyTier Default
```
產出：VM 清單 / 大小 / 開機狀態、需建立 NE 的網段、依規模 (300/600/1000) 估算波次數。
- 凡標示「需建立 NE」的網段，先以 `New-HcxNetworkExtension.ps1` 延伸完成並驗證 UP。

## 2. 波次 (Wave) 規劃

- 依相依性 (DB→AP→Web)、切換窗、頻寬與並行上限 (KB 373010：預設 300 / Medium 600 / Large 1000) 切分波次。
- 每波建議：先複製 (RAV/Bulk 都會先做 replication)，再於切換窗執行 cutover。
- 以清單檔管理每波 VM：`wave1.txt` (每行一個 VM 名稱)。

## 3. 提交遷移 (含 validate + 切換窗)

```powershell
# UAT 演練 (RAV，指定切換窗，提交後監控)
./scripts/change/Submit-HcxMigration.ps1 -Environment uat -MigrationType RAV -VMListFile ./wave1.txt `
    -ServiceMeshName SM-UAT -DestinationComputeName Cluster-Dst -DestinationDatastore DS-Dst `
    -DestinationNetwork 'app-seg' -SwitchoverStart '2026-06-01 22:00' -SwitchoverEnd '2026-06-01 23:30' -Monitor
```
腳本會：先 `action=validate` 驗證相容性 → 護欄確認 → `action=start` 提交 → (`-Monitor`) 輪詢至完成。

```powershell
# PROD (需提權 + 變更單號)
./scripts/change/Submit-HcxMigration.ps1 -Environment prod -MigrationType RAV -VMListFile ./wave1.txt `
    -ServiceMeshName SM-PROD -DestinationComputeName Cluster-Dst -DestinationDatastore DS-Dst `
    -DestinationNetwork 'app-seg' -SwitchoverStart '2026-06-07 22:00' -SwitchoverEnd '2026-06-08 02:00' `
    -ForceProdChange -ChangeTicket CHG0001234 -Monitor
```

## 4. Cutover (切換)

- **Bulk**：到切換窗時 HCX 自動於目的端開機並重啟切換 (來源關機)，期間短暫停機。
- **RAV**：複製完成後於切換窗對每台序列執行 vMotion 切換，幾乎零停機。
- 監控：`Get-HcxHealth.ps1` 看進行中遷移；或 `Submit-HcxMigration.ps1 -Monitor` 輪詢。
- 切換後驗證：目的端 VM 開機、IP/MAC 保留 (NE)、應用服務與監控正常。
- **MON 切換 gateway**：cutover 後若要讓流量直接走目的端 T0 (不再 trombone 回來源)，於目的端調整 MON Route Policy / 將該網段閘道切到 SDDC 端 (符合策略→回來源；否則走 T0)。

## 5. 收尾與下一波

- 確認本波無誤後，再啟動下一波 (`wave2.txt` ...)。
- 全部完成且穩定後，才考慮取消 Network Extension (將 L2 收斂回單站)，此為破壞性操作 → `Invoke-VCFChange -Impact Destructive`。

## 回退

- **Cutover 前**：來源 VM 仍開機且為權威副本，直接取消遷移即回退 (複製資料丟棄)。
- **Cutover 後**：來源已關機 / 退役，回退需「反向遷移」(目的→來源) 再切回；故 PROD 切換窗需預留回退時間，並保留來源 VM 一段觀察期 (勿立即刪除)。
- 任一波失敗：停止後續波次，保留已成功波次，依 validate / 健檢結果排錯後重試。

## 各環境注意事項

| 環境 | 注意 |
|------|------|
| UAT | 完整演練 validate→start→cutover 與監控；驗證波次切分與並行度。 |
| TEST | `RequireBackup=$true`；以接近 PROD 規模驗證頻寬與切換窗長度。 |
| PROD | 預設禁變更；需 `-ForceProdChange` + `-ChangeTicket` + 備份確認 + 環境名稱二次確認。嚴守切換窗、分波次、保留來源觀察期。大規模並行務必依 KB 373010 調整且不超 IX/NE 上限。 |

## 權威來源

- Migrating VMs with HCX (4.11): https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/vmware-hcx-user-guide-4-11/migrating-virtual-machines-with-vmware-hcx.html
- Mobility Groups / Migration Waves (4.11): https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/vmware-hcx-user-guide-4-11/migrating-virtual-machines-with-vmware-hcx/migrating-mobility-groups-from-migration-waves.html
- RAV / Bulk scalability (KB 373010): https://knowledge.broadcom.com/external/article/373010
- About HCX MON: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/about-hcx-mobility-optimized-networking.html
