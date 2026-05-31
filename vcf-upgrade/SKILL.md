---
name: vcf-upgrade
description: |
  涵蓋 VMware Cloud Foundation (VCF) 升級與導入的四種路徑：Deploy (全新/Greenfield)、Converge (既有 vSphere 收斂為 VVF/VCF)、Import (既有 vCenter 匯入為 Workload Domain)、Upgrade (VCF 5.x → 9.0.x/9.1)。提供升級順序、先決條件、版本需求、prechecks、備份/rollback 策略與已知問題。觸發關鍵字與情境：VCF 升級、VCF upgrade、VCF 9.0/9.1、5.2 to 9.0、5.2.x→9.1、vSphere 收斂、converge VVF、vCenter 匯入 import、workload domain、vLCM image 轉換、ELM 停用、vIDM/vIDB/Identity Broker、VCF Operations 強制元件、VCF Installer、VCF Management Services、License Server、Upgrade Planning Tool、skip-level upgrade、precheck、SDDC Manager、NSX/ESX/vCenter 升級序列、vSAN OSA、principal storage (vSAN/FC/NFS)、Aria Lifecycle/Fleet Management、VCD 不支援。當使用者詢問 VCF 升級規劃、相容性、版本最低需求、收斂/匯入流程、升級風險與回復時使用。
---

# VMware Cloud Foundation 升級 (Deploy / Converge / Import / Upgrade)

VCF 升級與導入的技術知識庫，涵蓋 Deploy / Converge / Import / Upgrade 四種路徑，
以及 VCF 5.x → 9.0.x / 9.1 的升級順序、先決條件與風險。產品版本細節搭配
`vcf-9`、`vcf-521` skill。

## 使用時機

當使用者詢問下列任一情境時使用本 skill：

- 規劃或執行 VMware Cloud Foundation 升級（VCF 5.x → 9.0.x，或 → 9.1）。
- 將既有獨立 vSphere 環境**收斂 (Converge)** 為 vSphere Foundation (VVF) 或 VCF。
- 將既有 vCenter / vSphere 環境**匯入 (Import)** 為 VCF Workload Domain。
- 全新**部署 (Deploy)** VCF Fleet / Management Domain。
- 評估升級**先決條件、版本最低需求、相容性、precheck、備份/回復策略、已知問題**。
- 處理 vLCM image 轉換、ELM 停用、vIDM→VIDB、Aria/VCF Operations 強制部署、授權變更等具體議題。

觸發中英關鍵字：VCF 升級 / VCF upgrade、Deploy / Converge / Import / Upgrade、5.2 to 9.0、5.2.x→9.1、skip-level、vSphere 收斂、workload domain、vLCM image、ELM、vIDB / Identity Broker、VCF Operations、VCF Installer、VCF Management Services、License Server、Upgrade Planning Tool、SDDC Manager、precheck、principal storage、vSAN OSA。

## 核心重點（先記住這幾點）

1. **四種路徑要分清楚**：Deploy（全新）、Converge（既有 vSphere 收斂）、Import（既有 vCenter 匯入為 WLD）、Upgrade（既有 VCF 升版）。流程、版本需求、工具都不同。
2. **VCF 9.0 部署典範轉移**：改以 **VCF Installer + VCF Operations 工作流程**為核心，不再是舊式 SDDC Manager 全自動 bring-up。
3. **升級順序固定**：VCF Operations 元件 → SDDC Manager → NSX → vCenter → ESX hosts。
4. **VCF Operations 是 9.0 強制元件**：即使原本沒用 Aria/LCM，升級時仍會部署 Aria Lifecycle（9.0 更名 **VCF Fleet Management**）與 VCF Operations。
5. **baselines 已死**：所有 ESX cluster 在 ESX 升級階段前必須由 baseline 轉為 **vLCM image**，VCF 9 不支援 baselines。
6. **ELM 不再支援**：匯入或收斂前必須先停用 Enhanced Linked Mode，其功能由 VCF Operations 接手。
7. **無完整 rollback**：以「每階段元件層級備份」作為個別失敗的回復檢查點。

更完整的逐步先決條件、checklist、版本對照與 Top 10 Q&A，見 `references/upgrade-5.2-to-9.0.md`。

## 版本與新功能

| 版本 | 狀態 / 釋出 | 與升級相關重點 |
|---|---|---|
| VCF 9.1 (9.1.0.0) | 2026/5/5 GA | 新增 **VCF Management Services**（整合 Fleet + SDDC lifecycle）與專屬 **License Server**；vIDB 多節點 cluster 直接遷入 Management Services；fleet 層與管理網域強制升級，WLD 可延後為 Day-N。 |
| VCF 9.0.2 (9.0.2.0) | 已釋出 | 可直接全新部署至 9.0.2，無須中間版本。 |
| VCF 9.0.1 (9.0.1.0) | 已釋出 | 含 NSX 收斂的最低目標之一。 |
| VCF 9.0.0 | 已釋出 | 不含 NSX 收斂的最低目標；NSX 須全新部署。 |
| VCF 5.2.x | 前一主要分支 | 升級至 9.0 / 9.1 的主要來源；早於 5.2 須先升到 5.2.x。 |

確切修補版號與最新累積釋出，一律以 techdocs.broadcom.com Release Notes 為準。

### VCF 9.1 新功能（升級相關）

- **VCF 9.1 Upgrade Planning Tool**（2026/5/28 公布）：依現況（vSphere 或 VCF、現有版本）產出可行升級目標、分階段工作流程、資源/網路需求、注意事項與文件連結，可匯出 PDF。<https://vmware.github.io/vcf-upgrade-planner/>
- **VCF Management Services**：整合 Fleet lifecycle 與 SDDC lifecycle；VCF Operations、Operations for logs/networks、Automation、Identity Broker 的生命週期管理於 VCF Operations 升 9.1 時轉移至此。
- **9.0.x→9.1 首步**通常為將 VCF Identity Broker 從 NSX overlay segment 轉移到管理網路（否則升級會失敗）。
- 9.0 的 vIDB 外部多節點 appliance cluster 於 9.1 直接遷入 Management Services，原獨立 VM 可關機除役。

### VCF 9.0 vs 5.x 重大變更

- 部署改以 VCF Installer + VCF Operations 工作流程為核心。
- VCF Operations 成為強制元件；Aria Lifecycle 更名 VCF Fleet Management。
- 移除 vLCM baselines，全面改用 vLCM images。
- ELM 不再支援，功能由 VCF Operations 接手。
- 管理網域主要儲存 (principal storage) 擴展為 **vSAN / Fibre Channel / NFS**（不再強制只能 vSAN）。
- 授權集中由 VCF Operations 跨 fleet 管理（透過 VCF Business Services console）；9.1 另引入專屬 License Server。
- VMware Cloud Director (VCD) 不支援、無遷移路徑。

## 與其他 skill 的關係

- 需要產出 VCF 9.1 升級簡報 → 使用 `anthropic-skills:vcf-91-ppt`（APJ Upgrade Pathways 模板）。
- 需要 VCF 簡報模板底層規格 → 參考 `anthropic-skills:broadcom-ppt-base`。
- 需要針對特定產業（金融、半導體、電信、混合雲、AI）的升級提案簡報 → 搭配對應的 `vcf-financial` / `vcf-semiconductor` / `vcf-telecom` / `vcf-hybrid-cloud` / `vcf-ai` skill。
- 本 skill 聚焦於**技術內容與升級邏輯本身**（路徑判斷、先決條件、版本需求），上述 skill 聚焦於**簡報產出**。

## 重要提醒（避免過時認知）

以下為已被 VCF 9.0/9.1 推翻的常見錯誤認知，回答時務必修正：

- ❌「VCF 部署一定走 SDDC Manager bring-up」→ 9.0 起改以 VCF Installer + VCF Operations 為核心。
- ❌「升級 VCF 不一定要 Aria/Operations」→ VCF Operations 為 9.0 強制元件，升級必定部署。
- ❌「ESX/cluster 可繼續用 vLCM baselines」→ 9 僅支援 vLCM images，升級前須完成轉換。
- ❌「ELM 可沿用」→ 9 不支援 ELM，匯入/收斂前須停用。
- ❌「vIDM 可升級為新身分服務」→ vIDM→VIDB 無直接升級/遷移路徑，須 greenfield 部署 VIDB。
- ❌「管理網域只能用 vSAN」→ 9 主要儲存支援 vSAN / FC / NFS。
- ❌「VCD 可移轉到 VCF 9」→ 不支援且無官方遷移路徑。
- ❌「vSAN OSA 已被棄用」→ OSA 仍受支援，惟須驗證硬體/韌體相容性。

> 涉及部署規模、IP/CIDR 數量、確切版本相容性等數字，務必以官方 techdocs Release Notes 與 Upgrade Planning Tool 為最終依據，勿憑記憶杜撰。

## 權威來源

- Deploy / Converge / Upgrade 總覽：<https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/deployment/overview-of-deploy--converge--and-upgrade.html>
- 升級 VCF (9.1)：<https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/upgrading-cloud-foundation.html>
- VCF 9.1.0.0 Release Notes：<https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes.html>
- 升級序列與相關問題 (KB)：<https://knowledge.broadcom.com/external/article/440630/upgrade-sequence-and-related-issues-for.html>
- 5.2→9.0 Top 10：<https://blogs.vmware.com/cloud-foundation/2025/12/18/upgrading-vmware-cloud-foundation-5-2-to-9-0-the-top-10-questions-answered/>
- Converge Top 10：<https://blogs.vmware.com/cloud-foundation/2026/04/16/converging-vmware-vsphere-to-vmware-cloud-foundation-9-0-the-top-10-questions-answered/>
- VCF 9.1 Upgrade Planning Tool：<https://blogs.vmware.com/cloud-foundation/2026/05/28/announcing-the-vmware-cloud-foundation-9-1-upgrade-planning-tool/>
- VCF 9.1 GA 公告：<https://blogs.vmware.com/cloud-foundation/2026/05/05/announcing-vcf-9-1-modern-private-cloud-built-for-efficiency-and-resilience/>

## 實戰操作 (Operations)

本章節提供可在真實環境執行的輔助腳本與操作手冊，協助 **VCF 5.2.x → 9.0.x / 9.1** 升級的「盤點 (precheck)、健檢 (healthcheck)、分階段觸發 (change)」。

> 重要：本層腳本**僅輔助盤點與觸發**，不取代官方流程。升級的可行性、目標版本、相容性與分階段步驟，一律以 **VCF Upgrade Planning Tool**（<https://vmware.github.io/vcf-upgrade-planner/>）與對應版本 **Release Notes** 為最終依據。

### 前置需求（共用 lib 框架）

所有 PowerShell 腳本都依賴 `lib/` 共用框架，**不得自行硬寫連線或明文密碼**：

```powershell
Import-Module ./lib/VCFGuardrails.psm1 -Force   # Get-VCFEnvironment / Invoke-VCFChange
Import-Module ./lib/VCFConnect.psm1    -Force   # Connect-VCFvCenter / Get-VCFRestToken / Get-VCFCredential / Disconnect-VCFAll
```

- 環境定義：複製 `lib/environments.example.psd1` 為 `lib/environments.psd1` 並填入 UAT / TEST / PROD 主機名與 `CredentialName`（`environments.psd1` 已被 `.gitignore` 排除）。
- 憑證：一律存於 PowerShell **SecretManagement**（`Set-Secret -Name vcf-prod -Secret (Get-Credential)`），腳本以 `Get-VCFCredential` 取用，**絕不寫死密碼**。
- 相依模組：`VMware.PowerCLI`、`Microsoft.PowerShell.SecretManagement`。REST 盤點之 Python 腳本需 `requests`；bash 腳本需 `curl` 與 `jq`。
- 所有腳本以 `-Environment <uat|test|prod>` 帶入環境，由 `Get-VCFEnvironment` 解析 Tier。

### scripts/ 內容

| 路徑 | 類型 | 說明 |
|---|---|---|
| `scripts/precheck/Invoke-VCFUpgradePrecheck.ps1` | 唯讀 | **最重要**。5.2.x→9.0/9.1 升級前全面盤點：各元件版本 vs 目標最低需求、cluster 是否已 vLCM image 化、ELM 是否啟用（需停用）、DVS 版本、備份狀態、VCF Operations 需求；輸出 PASS/FAIL 報表（HTML/CSV/JSON 可匯出）。 |
| `scripts/precheck/get_vcf_inventory.py` | 唯讀 | 純 REST 盤點（Python/requests）：透過 SDDC Manager Public API 取得 domains / clusters / hosts / bundles / upgradables，輸出 JSON 盤點清單。適合無 PowerCLI 的環境或 CI。 |
| `scripts/precheck/trigger_sddc_official_precheck.sh` | 唯讀觸發 | 以 curl 觸發 SDDC Manager 內建的官方 system precheck 並輪詢結果（bash/curl/jq）。非破壞性，僅啟動唯讀健康檢查工作流程。 |
| `scripts/healthcheck/Compare-VCFState.ps1` | 唯讀 | 升級前/後一致性驗證：擷取 host / cluster / 服務 / 版本快照（baseline / after），比對差異並標記異常。 |
| `scripts/change/Invoke-VCFStagedUpgrade.ps1` | change | 以 `Invoke-VCFChange` 包裝，分階段觸發升級（SDDC Manager → NSX → vCenter → ESX 順序），每階段輪詢狀態並設驗證 gate；PROD 強制護欄（二次確認/單號/備份）。 |

### runbooks/ 內容

| 檔案 | 說明 |
|---|---|
| `runbooks/upgrade-5.2-to-9.0-runbook.md` | VCF 5.2.x → 9.0.x 升級總流程：前置 remediation（vLCM image 化、移除 ELM、DVS 升級）、分階段升級、各環境注意事項、驗證與回退檢查點。 |
| `runbooks/upgrade-9.0-to-9.1-runbook.md` | VCF 9.0.x → 9.1 升級流程：Identity Broker 遷至管理網路、VCF Management Services 轉移、fleet/管理網域強制升級、WLD Day-N。 |
| `runbooks/upgrade-precheck-runbook.md` | precheck 盤點操作手冊：如何跑腳本、判讀 PASS/FAIL、對應 remediation。 |

### 安全分級提醒

- **唯讀優先**：precheck / healthcheck / 盤點一律唯讀，直接查詢、不改動環境。
- **變更必經護欄**：任何會改動環境的動作一律包在 `Invoke-VCFChange`，提供 `-Preview`（dry-run）與 `-Action`；**先 UAT/TEST、後 PROD**。
- **PROD 自動加嚴**：框架對 PROD 強制 `-ForceProdChange`、變更單號 (`-ChangeTicket`)、確認備份、輸入完整環境名稱二次確認，破壞性操作另需輸入 `DESTROY`。
- **不取代官方流程**：升級觸發後請於 SDDC Manager / VCF Operations UI 監看，遇錯依官方 KB 與 Release Notes 處置。
- API 路徑若版本間有差異，腳本內以註解標註「以官方 API 文件為準」並附官方連結；執行前請對照目標版本 API Reference。
