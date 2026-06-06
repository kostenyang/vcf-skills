---
name: vcf-9-ppt
description: |
  VMware Cloud Foundation 9 (9.0 與 9.1) 專門知識 skill。涵蓋 VCF 9 統一私有雲架構 (Organizational Private Cloud → VCF Fleet → VCF Instance → VCF Domains → vSphere Clusters)、VCF Operations 統一營運平面、VCF Automation 自助服務、Fleet Management、VCF Identity Broker、VCF Installer / SDDC Manager、API-first / OpenAPI 單一事實來源與跨語言 SDK (Python/Java/PowerCLI 9.1/Terraform v2.16.0)、vSphere 9 / ESX 9 / vSAN 9 / NSX 9、VKS (Kubernetes)、各版本 BOM 與 build 號、以及 9.0/9.0.1/9.0.2/9.1 的版本差異與新功能 (Enhanced NVMe Memory Tiering、ESX Live Patching、vSphere Elastic Provisioning、Real-Time Metrics API、Advanced Cyber Compliance、勒索復原)。當使用者詢問 VCF 9、VCF 9.0、VCF 9.1、VCF 9.0.1/9.0.2、vSphere Foundation 9、private cloud / 私有雲架構、VCF 9 部署/規劃/設計/POC、元件版本/BOM/build 號、Fleet/Instance/Domain 階層、或任何 9.x 技術細節與版本比較時觸發。也適用於 VCF 9 簡報、架構設計、版本差異查詢等需求。升級流程 (5.x→9.0、9.0→9.1) 請改用 vcf-upgrade-ppt skill。
---

# VMware Cloud Foundation 9 (9.0 / 9.1)

VCF 9 是 Broadcom 收購 VMware 後第一個「重大架構統一」版本，把過去鬆散的 SDDC + vRealize/Aria 套件整併為單一私有雲平台、單一安裝程式、單一 OpenAPI。本 skill 用來回答 VCF 9.0 與 9.1 的架構、元件、BOM、部署、規劃與版本差異。

> 截至 2026-05-31 的最新版本：**VCF 9.1.0.0（GA 2026-05-12，Build 25377994）**；9.0 線最新維護版為 **VCF 9.0.2.0（GA 2026-01-20）**。VCF 9.0 首發 GA 為 2025-06-17（Build 24755599）。

## 使用時機

- 規劃或設計 VCF 9 私有雲架構（Fleet / Instance / Domain 階層）
- 比較 VCF 9.0 vs 9.1，或 VCF 9 vs VCF 5.x
- VCF 9 元件版本、相容性、BOM、build 號查詢
- VCF 9 部署 (Deploy)、轉換 (Converge)、匯入 (Import) 工作流程
- 撰寫 VCF 9 簡報、POC 計畫、技術文件、版本差異說明

> 升級流程 (5.x → 9.0、9.0 → 9.1) 請改用 `vcf-upgrade-ppt` skill；製作簡報請改用對應的 `vcf-91-ppt` 等 PPT skill。

## VCF 9 核心架構重點

1. **統一私有雲平台**：組織階層為 Organizational Private Cloud → **VCF Fleet** → **VCF Instance** → **VCF Domains**（管理域 / 工作負載域）→ **vSphere Clusters**。不再是「vSphere + vSAN + NSX + Aria 拼裝」。
2. **VCF Operations = 單一統一管理介面**：整合效能監控、集中授權、Fleet 管理與整體營運，取代過去分散的 vROps / Aria Operations 工具孤島。每個 Fleet 僅有一個 VCF Operations 實例。
3. **VCF Automation = 自助服務平面**：透過 VCF Automation Console 進行服務佈建、部署與生命週期管理，取代 Aria Automation。每個 Fleet 僅有一個 VCF Automation 實例。
4. **Fleet Management（艦隊管理）**：自動化關鍵生命週期作業 — 修補、升級、break-glass 密碼、憑證輪替等。
5. **VCF Identity Broker**：全新身分驗證中介，介於 IdP 與 VCF 元件（vCenter、NSX、VCF Operations/Automation）之間，支援 SAML / OIDC，於 Fleet 層級套用全域設定（ESXi 與 SDDC Manager 仍需個別設定）。
6. **VCF Installer / SDDC Manager**：單一安裝程式即可部署元件；SDDC Manager 角色轉變，大量生命週期作業改由 VCF Installer / Fleet Management 接手。
7. **API-first / Unified SDK**：以 OpenAPI 為單一事實來源；9.1 達成跨 Python / Java / PowerCLI / Terraform 的功能對等 (functional symmetry)。

> 重要校正：VCF 9 已**非**傳統「SDDC Manager 為核心 + vRealize Suite」架構。vRealize 已更名整併為 VCF Operations / VCF Automation，這個舊認知已過時。

## 版本與新功能（速查表）

### VCF 9 版本時間線

| 版本 | GA 日期 | Build / 備註 |
|------|---------|--------------|
| VCF 9.0（首發） | 2025-06-17 | Build 24755599，建立統一架構基礎 |
| VCF 9.0.1.0 | 2025-09-29 | 維護版，更新 BOM、聚焦可支援性 |
| VCF 9.0.2.0 | 2026-01-20 | 維護版（9.0 線最新），bug/安全修補、硬體啟用 |
| **VCF 9.1.0.0** | **2026-05-12** | **Build 25377994，目前最新主要版本** |

### VCF 9.1 相對 9.0 的新功能重點

| 主題 | VCF 9.1 新功能 |
|------|----------------|
| 架構 | VCF Management Services：統一 runtime 與元件，整合生命週期與營運架構 |
| 記憶體效率 | Enhanced NVMe Memory Tiering（熱頁留 DRAM、冷頁卸載 NVMe，含軟體鏡像，官方稱約 40% TCO 降低） |
| 儲存 | 全域 / 擴展 vSAN Deduplication & Compression，支援加密資料 (at rest) 去重 |
| 佈建 | vSphere Elastic Provisioning（Zero Touch 裸機 ESX，UEFI/HTTP-S 網路影像、平行影像與自動發現） |
| 規模 | 支援多達 5,000 台 ESX 主機、平行生命週期作業；VKS 每 Supervisor 達 500 叢集 |
| 部署加速 | VKS 與 VM Fast-Deploy（linked clone 加速部署 / 升級） |
| 容器 | 簡化 CaaS：自助 namespace 佈建，繼承 registry / ingress / quota / identity |
| 物件儲存 | Native Object Storage（S3 相容，Tech Preview） |
| 資安 | ESX Live Patching（限 TPM 主機，無維護視窗，涵蓋約 80% 修補） |
| API | Real-Time Metrics API（Prometheus 相容、2 秒粒度、PromQL、Grafana）、VGFA、vCenter Server Query API；PowerCLI 9.1、Terraform Provider v2.16.0 |
| vMotion | vMotion Encryption Offload（硬體加速，約節省 70% CPU） |
| 合規 | Advanced Cyber Compliance (ACC) 持續性修復、PCI DSS 自動評估 |
| 勒索復原 | 地端 cyber recovery clean room、vSAN for Recovery、CrowdStrike EDR 整合 |
| 生態 | 網路夥伴 Arista / Cisco / SONiC；AMD Instinct MI350 GPU DirectPath I/O |
| 應用 | Live Application Stack Blueprints（擷取執行中應用轉為可重複範本） |

詳細內容、完整 BOM、build 號與 checklist 見：
- `references/vcf-9.0.md` — VCF 9.0 / 9.0.1 / 9.0.2 架構基礎與維護版重點
- `references/vcf-9.1.md` — VCF 9.1 完整 BOM、新功能與技術細節

## 與其他 skill 的關係

- **`vcf-upgrade-ppt`**：5.x → 9.0、9.0 → 9.1 升級流程、前置條件與元件升級順序。
- **`vcf-91-ppt` / `vcf-ai` / `vcf-financial` 等 PPT skill**：以官方 Broadcom 範本製作 VCF 簡報。本 skill 負責提供技術內容與版本事實。
- 本 skill 專注於 **VCF 9 架構知識與版本事實**，是上述 skill 的技術後盾。

## 重要提醒

- VCF 9 全面採 vLCM **image-based** 管理，傳統 baseline 管理不再使用。
- 官方數字（40% TCO、70% CPU、80% 修補、5,000 主機、500 叢集/Supervisor）來自官方部落格/文件描述，正式專案以官方文件與實際環境為準。
- 部分元件 build 號未於 Release Notes 主頁完整列出（如 VCF 9.0.2），以官方 **Bill of Materials** 頁面為準。
- 升級至 9.1 須嚴格遵守元件升級順序（以官方升級指南為準）。

## 權威來源

- VCF 9.1 What's New: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes/what-s-new.html
- VCF 9.1 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes.html
- VCF 9.1 Bill of Materials: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes/vmware-cloud-foundation-bill-of-materials.html
- VCF 9.0 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/release-notes/vmware-cloud-foundation-90-release-notes.html
- VCF 9.0.1 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/release-notes/vmware-cloud-foundation-9-0-1-release-notes.html
- VCF 9.0.2 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/release-notes/vmware-cloud-foundation-9-0-2-release-notes.html
- VCF 9.1 公告部落格: https://blogs.vmware.com/cloud-foundation/2026/05/05/announcing-vcf-9-1-modern-private-cloud-built-for-efficiency-and-resilience/
- VCF 9.1 Programmable Infrastructure 部落格: https://blogs.vmware.com/cloud-foundation/2026/05/25/unlocking-the-full-potential-of-programmable-infrastructure-with-vmware-cloud-foundation-9-1-new-features-and-capabilities/
- VCF 9.1 Solution Brief: https://www.vmware.com/docs/vmware-cloud-foundation-9-1-solution-brief

## 實戰操作 (Operations)

本章節提供可在真實環境執行的腳本與 runbook，作為 VCF 9 知識的「動手層」。所有腳本一律套用 repo 根目錄的共用框架 `lib/`，遵循「健檢唯讀、變更走護欄、PROD 自動加嚴、先測試環境」原則。

### 前置：共用框架 (lib/)
所有 PowerShell 腳本開頭都會載入：
```powershell
Import-Module ./lib/VCFGuardrails.psm1 -Force   # Get-VCFEnvironment / Invoke-VCFChange
Import-Module ./lib/VCFConnect.psm1   -Force     # Connect-VCFvCenter / Get-VCFRestToken / Get-VCFCredential / Disconnect-VCFAll
```
使用前須先：
1. 由 `lib/environments.example.psd1` 複製成 `lib/environments.psd1`，填入 uat/test/prod 的 SddcManager/vCenter/Nsx/HcxManager 與 Tier。
2. 將各環境憑證存入 SecretManagement：`Set-Secret -Name vcf-prod -Secret (Get-Credential)`（絕不寫死密碼/IP）。
3. 環境一律以 `-Environment <uat|test|prod>` 帶入，由 `Get-VCFEnvironment` 解析；PROD 由框架自動加嚴（二次確認 / 變更單號 / 備份確認 / 強制先 dry-run）。
- Python/bash 等非 PowerShell 腳本同樣遵循「先預覽、PROD 二次確認、先測試環境」，帳密以環境變數或 vault 注入。
- 所有 SDDC Manager / NSX REST 路徑以官方 API 文件為準：https://developer.broadcom.com/xapis （VMware Cloud Foundation API Reference）。

### 安全分級 (務必先看)
- **ReadOnly**：唯讀健檢/盤點，可直接於 PROD 執行，不改動環境。
- **Change**：會改動環境，包在 `Invoke-VCFChange` 內，UAT/TEST 單次確認、PROD 需 `-ForceProdChange` + `-ChangeTicket`。
- **Destructive**：高風險變更（套用升級、decommission），PROD 另需輸入 `DESTROY` 二次確認。
> 規則：健檢/precheck 絕不改動環境；任何變更先在 UAT/TEST 演練，PROD 必在維護視窗、備份就緒下進行。

### scripts/
| 路徑 | 分級 | 說明 |
|------|------|------|
| `scripts/healthcheck/Get-Vcf9Health.ps1` | ReadOnly | REST+PowerCLI 綜合健檢：SDDC/Domain/Cluster/Host 版本與狀態、vSAN 健康、NSX 叢集狀態、系統告警，可輸出 JSON |
| `scripts/healthcheck/Get-Vcf9PasswordCertExpiry.ps1` | ReadOnly | 盤點 SDDC Manager 管理的帳密輪替時間與憑證到期，依 `-WarnDays` 標記即將到期者 |
| `scripts/healthcheck/vcf9_fleet_inventory.py` | ReadOnly | 純 REST（Python/requests）Fleet/Domain/Cluster/Host 盤點，適合無 PowerCLI 的 Linux 跳板機；帳密走 `VCF_USER`/`VCF_PASS` 環境變數 |
| `scripts/precheck/Invoke-Vcf9UpgradePrecheck.ps1` | ReadOnly | 升級/擴充前盤點：目前版本 vs 可用 upgradables、cluster 是否 vLCM image-based、告警清零檢查、vSAN 容量緩衝 |
| `scripts/change/Set-Vcf9HostMaintenance.ps1` | Change | ESX host 進入/離開維護模式（PowerCLI），含 vSAN 資料疏散策略，包在 `Invoke-VCFChange` |
| `scripts/change/Invoke-Vcf9BundleLifecycle.ps1` | Change / Destructive | 觸發 LCM bundle 下載（Change）或套用升級（Destructive）並輪詢任務狀態，僅觸發不取代官方升級程序 |
| `scripts/change/Invoke-Vcf9HostCommission.ps1` | Change / Destructive | commission（納管，Change）/ decommission（移除，Destructive）ESX host，被納管 host 帳密由 SecretManagement 取得 |

### runbooks/
| 檔案 | 內容 |
|------|------|
| `runbooks/vcf9-daily-healthcheck.md` | VCF 9 日常健檢（唯讀）：前置、步驟、健康判準、各環境注意事項 |
| `runbooks/vcf9-host-maintenance-rotation.md` | ESX host 維護模式逐台輪替：進入/離開、vSAN 疏散、驗證與回退 |
| `runbooks/vcf9-bundle-apply.md` | LCM bundle 下載與套用四階段（precheck → 下載 → TEST 演練 → PROD 套用 → 驗證），含回退原則 |

> 升級的元件順序、相容性與回退一律以 Broadcom 官方升級指南與 Bill of Materials 為準；腳本只負責安全地觸發與輪詢官方任務。
