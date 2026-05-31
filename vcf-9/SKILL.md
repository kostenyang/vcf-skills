---
name: vcf-9
description: |
  VMware Cloud Foundation 9 (9.0 與 9.1) 專門知識 skill。涵蓋 VCF 9 統一私有雲架構 (Organizational Private Cloud → VCF Fleet → VCF Instance → VCF Domains → vSphere Clusters)、VCF Operations 統一營運平面、VCF Automation 自助服務、Fleet Management、VCF Identity Broker、VCF Installer / SDDC Manager、API-first / OpenAPI 單一事實來源與跨語言 SDK (Python/Java/PowerCLI 9.1/Terraform v2.16.0)、vSphere 9 / ESX 9 / vSAN 9 / NSX 9、VKS (Kubernetes)、各版本 BOM 與 build 號、以及 9.0/9.0.1/9.0.2/9.1 的版本差異與新功能 (Enhanced NVMe Memory Tiering、ESX Live Patching、vSphere Elastic Provisioning、Real-Time Metrics API、Advanced Cyber Compliance、勒索復原)。當使用者詢問 VCF 9、VCF 9.0、VCF 9.1、VCF 9.0.1/9.0.2、vSphere Foundation 9、private cloud / 私有雲架構、VCF 9 部署/規劃/設計/POC、元件版本/BOM/build 號、Fleet/Instance/Domain 階層、或任何 9.x 技術細節與版本比較時觸發。也適用於 VCF 9 簡報、架構設計、版本差異查詢等需求。升級流程 (5.x→9.0、9.0→9.1) 請改用 vcf-upgrade skill。
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

> 升級流程 (5.x → 9.0、9.0 → 9.1) 請改用 `vcf-upgrade` skill；製作簡報請改用對應的 `vcf-91-ppt` 等 PPT skill。

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

- **`vcf-upgrade`**：5.x → 9.0、9.0 → 9.1 升級流程、前置條件與元件升級順序。
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
