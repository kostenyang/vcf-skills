# Runbook：VCF 5.2.x → 9.0.x 升級總流程

> 本 runbook 為輔助操作手冊，**不取代官方升級流程**。所有版本/相容性/步驟以官方 **VCF Upgrade Planning Tool**、目標版本 **Release Notes** 與 KB（升級序列：<https://knowledge.broadcom.com/external/article/440630/>）為最終依據。

## 升級順序（固定）

```
VCF Operations / Fleet 元件  →  SDDC Manager  →  NSX  →  vCenter  →  ESX hosts
```

## 前置 Remediation（升級前必須完成）

1. **官方規劃工具**：跑 VCF Upgrade Planning Tool，確認可行目標版本與分階段流程。
2. **全面盤點**：執行 `upgrade-precheck-runbook.md` 全流程，所有 FAIL 清為 PASS。
3. **vLCM image 化**：所有 ESX cluster 由 baseline 轉為 vLCM image（VCF 9 不支援 baselines）。
4. **停用 ELM**：停用 Enhanced Linked Mode（VCF 9 不支援，功能由 VCF Operations 接手）。
5. **DVS 升級**：依目標版本需求升級 DVS。
6. **備份**：SDDC Manager / NSX / vCenter 完成備份並驗證可還原。
7. **VCF Operations / Fleet**：規劃強制部署所需資源、IP/DNS（9.0 強制元件，Aria Lifecycle 更名 VCF Fleet Management）。
8. **建立 baseline 快照**（升級後比對用）：
   ```powershell
   ./scripts/healthcheck/Compare-VCFState.ps1 -Environment <env> -Mode Capture -SnapshotPath ./before-<env>.json
   ```

## 升級步驟

### 階段 0：VCF Operations / Fleet（依官方於 VCF Operations 介面）

依官方流程先完成 VCF Operations / Fleet 元件升級/部署。此階段不由本腳本觸發。

### 階段 1–4：SDDC Manager → NSX → vCenter → ESX（分階段觸發 + gate）

先下載對應 bundle，取得各階段 `bundleId`（`/v1/bundles` 或 `/v1/upgradables`）與 `domainId`（`/v1/domains`）。

單階段（建議逐階段執行，每階段後做健檢 gate）：
```powershell
# 1) SDDC Manager
./scripts/change/Invoke-VCFStagedUpgrade.ps1 -Environment <env> -DomainId <d> -Stage SDDC -BundleId <b1>
# 健檢 gate
./scripts/healthcheck/Compare-VCFState.ps1 -Environment <env> -Mode Compare -SnapshotPath ./before-<env>.json
# 2) NSX → 3) vCenter → 4) ESX 同理，逐階段並在每階段後做 gate
```

全序列（每階段間會要求輸入 `yes` 才續行；PROD 每階段都會被護欄攔下）：
```powershell
./scripts/change/Invoke-VCFStagedUpgrade.ps1 -Environment <env> -DomainId <d> -Stage ALL `
    -BundleMap @{SDDC='b1';NSX='b2';VCENTER='b3';ESX='b4'}
```

## 各環境注意事項

- **UAT**：先完整演練一輪（含 remediation 與全序列升級），確認流程與 gate。
- **TEST**：貼近正式資料/規模再演練一次；確認備份還原可行。
- **PROD**：
  - 變更腳本須加 `-ForceProdChange -ChangeTicket <單號>`；框架會要求確認備份、二次輸入環境名稱。
  - **逐階段**執行，每階段後務必跑健檢 gate，確認無異常再續行。
  - 安排維運時窗與回退決策點；通知相關團隊。

## 驗證

每階段後：
```powershell
./scripts/healthcheck/Compare-VCFState.ps1 -Environment <env> -Mode Compare -SnapshotPath ./before-<env>.json
```
確認：所有 host `Connected`、無消失主機、cluster HA/DRS 正常、版本如預期提升。

## 回退檢查點（無完整 rollback）

VCF 升級**沒有單鍵 rollback**。以「每階段元件層級備份/快照」作為個別失敗的回復檢查點：

- 每階段前：確認該元件備份/快照存在且可還原。
- 階段失敗：停在該階段，依官方 KB 與 SDDC Manager UI 的 retry / resolve 處理；必要時用該元件備份還原該元件，**不要跳階段續行**。
- 切勿在某階段失敗未解時觸發下一階段。
