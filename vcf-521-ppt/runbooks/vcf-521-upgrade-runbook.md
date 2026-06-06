# Runbook：VCF 5.2 → 5.2.1 / Skip-Level 升級

> 目的：以共用框架護欄安全執行 VCF 升級。所有變更走 `Invoke-VCFChange`，先 dry-run、先測試、PROD 加嚴。
> 相關腳本：`scripts/precheck/`、`scripts/change/`。

## 1. 前置

- 完成 `vcf-521-healthcheck-runbook.md` 健檢，環境健康。
- SDDC Manager、vCenter、NSX 等已建立**可驗證**的備份/快照。
- Depot 連線與認證可用（**KB 390098**：Depot 驗證方式已變更，需有效下載 token / Broadcom 帳號繫結）。
- 確認 **SSH 狀態**（**KB 86230**：5.2 起預設關閉）；若流程需暫時開啟，事後立即關閉。
- 已規劃維護視窗；PROD 已取得變更單號（`-ChangeTicket`）。
- 版本路徑與相容性以 Broadcom TechDocs Release Notes / Upgrade Path 為準（支援循序與跳版）。

## 2. Precheck（唯讀）

```powershell
./scripts/precheck/Test-Vcf521UpgradePrereq.ps1 -Environment <env> -RunSddcPrecheck
# 快速 Depot/bundle 連線驗證 (bash)
VCF_USERNAME=... VCF_PASSWORD=... ./scripts/precheck/check_depot_connectivity.sh --sddc <fqdn>
```

檢查項：Depot 連線、目標 bundle 已 `SUCCESSFUL` 下載、SDDC Manager 內建 precheck 全綠、baseline 叢集清單（見 vLCM runbook）。

## 3. 升級步驟

> 順序：先下載 bundle → SDDC Manager 先升 → 再升各 Workload Domain（vCenter → NSX → ESXi）。本 runbook 涵蓋前兩步的腳本化；網域元件升級建議於 SDDC Manager UI 逐域執行並全程監控。

| 步驟 | 指令 |
| --- | --- |
| 3.1 下載 bundle | `./scripts/change/Invoke-Vcf521BundleDownload.ps1 -Environment <env> -BundleId <id>` |
| 3.2 SDDC Manager 升級 | `./scripts/change/Invoke-Vcf521SddcManagerUpgrade.ps1 -Environment <env> -BundleId <id> -ResourceId <id>` |
| 3.3 host 維護（如需） | `./scripts/change/Set-Vcf521HostMaintenance.ps1 -Environment <env> -VMHostName <fqdn> -Action Enter` |
| 3.4 網域元件升級 | 於 SDDC Manager UI 對各 Workload Domain 套用升級（vCenter RDU → NSX → ESXi） |

**PROD 範例（加嚴）：**
```powershell
./scripts/change/Invoke-Vcf521SddcManagerUpgrade.ps1 -Environment prod -BundleId <id> -ResourceId <id> -ForceProdChange -ChangeTicket CHG0012345
```
PROD 會要求：確認已備份 → 完整輸入環境名稱 → （破壞性操作）輸入 `DESTROY`。

## 4. 各環境注意事項

- **UAT**：先全流程演練，確認 bundle id / resource id / API 行為正確。
- **TEST**：以接近 PROD 的拓樸驗證升級時間與相依性。
- **PROD**：務必維護視窗內、單號齊備、備份驗證過；逐域、逐步、全程監控；勿在升級任務進行中中斷。

## 5. 驗證

- 升級任務狀態 `SUCCESSFUL`（`GET /v1/upgrades/{id}` 或 UI）。
- 重跑 `Get-Vcf521ServiceAndBom.ps1` 確認版本/build 已達目標。
- 重跑健檢，host/cluster/服務全綠。

## 6. 回退

- SDDC Manager / vCenter：自升級前**快照或備份還原**（VCF 升級不支援滾回，須以備份還原）。
- host：`Set-Vcf521HostMaintenance.ps1 ... -Action Exit` 離開維護模式恢復服務。
- 任一階段失敗：保留任務 log、開 Broadcom 支援單，依官方還原指引處理。
