# VMware Cloud Foundation 9 完整指南（VCF 9.0 / 9.1）

> 本文件可獨立閱讀，整理 VMware Cloud Foundation 9（VCF 9.0、9.0.1、9.0.2 與 9.1）的架構、版本、元件 BOM、新功能、規劃 checklist 與 FAQ。資料截至 **2026-05-31**。技術名詞保留英文。

---

## 目錄

1. [概觀與版本時間線](#1-概觀與版本時間線)
2. [VCF 9 統一架構](#2-vcf-9-統一架構)
3. [VCF 9.0 架構基礎](#3-vcf-90-架構基礎)
4. [VCF 9.0.1 / 9.0.2 維護版](#4-vcf-901--902-維護版)
5. [VCF 9.1 新功能](#5-vcf-91-新功能)
6. [VCF 9.1 Bill of Materials](#6-vcf-91-bill-of-materials)
7. [官方宣稱數字（核對表）](#7-官方宣稱數字核對表)
8. [規劃與導入 Checklist](#8-規劃與導入-checklist)
9. [常見問答 FAQ](#9-常見問答-faq)
10. [參考來源](#10-參考來源)

---

## 1. 概觀與版本時間線

VCF 9 是 Broadcom 收購 VMware 後第一個「重大架構統一」版本，將過去鬆散的 SDDC + vRealize/Aria 套件整併為單一私有雲平台、單一安裝程式、單一 OpenAPI。

| 版本 | GA 日期 | Build / 性質 |
|------|---------|--------------|
| VCF 9.0（首發 / GA） | 2025-06-17 | Build 24755599，建立統一架構基礎 |
| VCF 9.0.1.0 | 2025-09-29 | 維護版，更新 BOM、聚焦可支援性 |
| VCF 9.0.2.0 | 2026-01-20 | 維護版（9.0 線最新），bug/安全修補、硬體啟用 |
| **VCF 9.1.0.0** | **2026-05-12** | **Build 25377994，目前最新主要版本**（官方部落格首次公告 2026-05-05） |

---

## 2. VCF 9 統一架構

### 2.1 組織階層

```
Organizational Private Cloud
  └─ VCF Fleet            （艦隊：生命週期與營運的最大邊界）
       └─ VCF Instance    （實例）
            └─ VCF Domains （管理域 / 工作負載域）
                 └─ vSphere Clusters
```

### 2.2 核心平面

| 平面 | 角色 | 取代的舊產品 |
|------|------|--------------|
| **VCF Operations** | 單一統一管理介面：效能監控、集中授權、Fleet 管理、整體營運 | vROps / Aria Operations 等分散工具孤島 |
| **VCF Automation** | 自助服務平面：服務佈建、部署、生命週期（VCF Automation Console） | Aria Automation |
| **Fleet Management** | 自動化生命週期：修補、升級、break-glass 密碼、憑證輪替 | 分散的 LCM 流程 |
| **VCF Installer / SDDC Manager** | 單一安裝程式部署元件；SDDC Manager 角色轉變 | 傳統 SDDC Manager 核心 |
| **VCF Identity Broker** | IdP 與 VCF 元件間中央身分中介（SAML / OIDC） | 各元件分散身分整合 |

> 每個 Fleet **僅有一個** VCF Operations 實例與**一個** VCF Automation 實例。

### 2.3 重要架構認知校正

- VCF 9 已**非**傳統「SDDC Manager 為核心 + vRealize Suite」架構。
- 自 9.0 起改以 VCF Operations 為統一營運平面、VCF Automation 為自助服務平面。
- vRealize 已更名整併為 VCF Operations / VCF Automation，舊認知已過時。
- VCF Identity Broker 於 **Fleet 層級**套用全域身分設定；**ESXi 與 SDDC Manager 仍需個別設定**。

---

## 3. VCF 9.0 架構基礎

VCF 9.0（2025-06-17 GA）改為統一、模組化的私有雲平台，相對 VCF 5.x 是根本性轉變。

引入能力：

- **Fleet → Instance → Domain → Cluster** 組織階層。
- **VCF Operations** 單一統一管理介面。
- **VCF Automation** 自助服務佈建。
- **Fleet Management** 自動化關鍵生命週期作業。
- **VCF Identity Broker**：SAML / OIDC，Fleet 層級全域設定。
- **VPC networking**、自動化憑證處理。
- **converge / import 工作流程**：將既有 vSphere 環境轉換或匯入 VCF。
- 全面採 **vLCM image-based** 管理（baseline 管理不再使用）。

---

## 4. VCF 9.0.1 / 9.0.2 維護版

### 4.1 VCF 9.0.1.0（2025-09-29 GA）
- 維護版，更新 BOM，聚焦可支援性（bug / 安全修補、硬體啟用）。

### 4.2 VCF 9.0.2.0（2026-01-20 GA）
維護版定位：更新 BOM，聚焦可支援性（bug/安全修補、硬體啟用、向後相容新功能）。

- **vCenter 9.0.2.0**
  - VMCA 簽發的 vCenter / ESX SSL 憑證接近到期時**自動更新**（machine SSL 在到期少於 5 天時自動延長 2 年）。
  - Supervisor 控制平面備份於 VAMI **預設啟用**。
- **VCF Operations 9.0.2.0**
  - Diagnostics 框架新增 **154 個 signature**（對應 148 個已知問題、4 個最佳實務、2 個基於 VMware Security Advisory）。
  - SMTP 通知外掛支援 **Microsoft 365 OAuth 2.0** 驗證。

---

## 5. VCF 9.1 新功能

### 5.1 架構
- **VCF Management Services**：新增共用 runtime 與一組元件，統一生命週期與營運能力的架構。

### 5.2 基礎架構效率
- **Enhanced NVMe Memory Tiering**：熱頁留 DRAM、冷頁卸載本地 NVMe，擴大有效記憶體不需額外 DRAM；含軟體鏡像與成本分析（官方稱約 40% TCO 降低）。
- **vSAN 全域 / 擴展 Deduplication & Compression**：跨叢集類型與工作負載擴大內嵌資料縮減，支援加密資料 (at rest) 去重。
- **vSphere Elastic Provisioning（Zero Touch）**：以網路影像（UEFI、HTTP/S）裸機自動 bootstrap 與設定 ESX，支援平行影像與自動發現。
- **規模**：支援多達 5,000 台 ESX 主機，平行生命週期作業。

### 5.3 應用交付 / 開發者體驗
- **API-first**：OpenAPI 為單一事實來源，自動產生各語言 SDK，達成 Python / Java / PowerCLI / Terraform 功能對等。SDK 經 Broadcom Developer Portal、PyPI、Maven Central 發布。
- 新 API：**Real-Time Metrics API**（Prometheus 相容、2 秒粒度、PromQL、Grafana，涵蓋 ESX/vCenter/vSAN/NSX）、**vCenter Utilization API**、**vCenter Group Federated API (VGFA)**、**vCenter Server Query API**（類 SQL、伺服器端篩選分頁）。
- **PowerCLI 9.1**：CPU topology (Assigned at PowerOn)、NVMe over TCP VMkernel、vSAN remote datastore 指令、VPC 網路指令、OAuth SSO、ESXi proxy-backed AD 身分。
- **vSphere Terraform Provider v2.16.0**：Project VPC、vSphere Zones、CPU topology、EVC、Supervisor 等。
- **vMotion Encryption Offload**：硬體加速，約節省 70% CPU。
- **VKS**：每 Supervisor 至 500 叢集。
- **VKS 與 VM Fast-Deploy**：linked clone 加速部署 / 升級。
- **簡化 CaaS**：自助 namespace 佈建，繼承 registry / ingress / quota / identity。
- **Native Object Storage（Tech Preview）**：S3 相容、開發者導向、具 IT 治理。
- **Live Application Stack Blueprints**：擷取執行中應用轉為可重複範本。

### 5.4 資安韌性 / 合規
- **ESX Live Patching（限 TPM 主機）**：修補套用於執行中 kernel memory，VM 持續運作、無維護視窗，涵蓋約 80% 修補。
- **Advanced Cyber Compliance (ACC)**：持續性修復、統一安全態勢、對 VCF 指引與 PCI DSS 自動評估。
- **地端勒索軟體復原**：cyber recovery clean room、vSAN for Recovery 原生快照式複製、CrowdStrike EDR 整合（隔離環境掃描）。

### 5.5 生態系
- 網路夥伴：Arista、Cisco、SONiC。
- AMD Instinct MI350 系列 GPU 支援 DirectPath I/O。

---

## 6. VCF 9.1 Bill of Materials

主要元件皆為 9.1.0.0：

| 元件 | 版本 | Build |
|------|------|-------|
| ESX | 9.1.0.0 | 25370933 |
| vCenter | 9.1.0.0 | 25370922 |
| NSX | 9.1.0.0 | 25318225 |
| vSAN ESA Witness | 9.1.0.0 | 25370927 |
| vSAN OSA Witness | 9.1.0.0 | 25370925 |
| vSAN File Services | 9.1.0.0 | 25370922 |
| VCF Operations | 9.1.0.0 | 25346025 |
| VCF Operations for Networks | 9.1.0.0 | 25318550 |
| VCF Automation | 9.1.0.0 | 25370929 |
| VCF Installer / SDDC Manager | 9.1.0.0 | 25371088 |

> 完整 BOM 含 VCF Operations for Logs / Fleet Management 等其餘元件，以官方 BOM 頁面為準。

---

## 7. 官方宣稱數字（核對表）

| 指標 | 數字 | 來源性質 |
|------|------|----------|
| Memory Tiering TCO 降低 | 約 40% | 官方部落格 / 文件描述 |
| vMotion Encryption Offload CPU 節省 | 約 70% | 官方描述 |
| ESX Live Patching 修補覆蓋 | 約 80% | 官方描述 |
| ESX 主機規模上限 | 5,000 | 官方描述 |
| VKS 每 Supervisor 叢集數 | 500 | 官方描述 |

> 上述數字以官方文件與實際環境為準，正式專案勿直接引為承諾值。

---

## 8. 規劃與導入 Checklist

### 8.1 VCF 9.0 導入
- [ ] 確認目標版本：新案建議直接評估 9.1；既有 9.0 環境確認是否需升至 9.0.2。
- [ ] 規劃 Fleet / Instance / Domain 階層與邊界。
- [ ] 每 Fleet 單一 VCF Operations + 單一 VCF Automation 容量規劃。
- [ ] 設計 VCF Identity Broker 與 IdP 整合（SAML / OIDC），保留 ESXi / SDDC Manager 個別設定。
- [ ] 規劃 VPC networking 與自動化憑證處理。
- [ ] 既有環境評估 converge / import 可行性。
- [ ] 確認採 vLCM image-based 管理。

### 8.2 VCF 9.1 評估 / 導入
- [ ] 以官方 BOM 核對全部元件版本 / build 號（皆 9.1.0.0）。
- [ ] 評估 Enhanced NVMe Memory Tiering 硬體（本地 NVMe）與成本分析。
- [ ] 規劃 vSphere Elastic Provisioning 網路影像基礎（UEFI / HTTP-S、自動發現）。
- [ ] 確認 ESX Live Patching 前提：主機需 TPM-enabled。
- [ ] 選定 API-first SDK 語言（Python/Java/PowerCLI 9.1/Terraform v2.16.0）。
- [ ] 即時監控整合評估 Real-Time Metrics API（Prometheus/Grafana/PromQL）。
- [ ] 合規對應 Advanced Cyber Compliance（PCI DSS、持續性修復）。
- [ ] 勒索復原評估 vSAN for Recovery clean room 與 CrowdStrike EDR。
- [ ] 規模 / 並行升級規劃（至 5,000 ESX、VKS 500 叢集/Supervisor）。
- [ ] GPU 工作負載確認硬體（AMD Instinct MI350 DirectPath I/O）與網路夥伴 (Arista/Cisco/SONiC)。
- [ ] 升級至 9.1 前確認元件升級順序（官方升級指南）。

---

## 9. 常見問答 FAQ

**Q1. 目前 VCF 9 最新版本是哪一個？**
A. VCF 9.1.0.0（GA 2026-05-12，Build 25377994）。9.0 線最新維護版為 9.0.2.0（2026-01-20）。

**Q2. VCF 9 還是以 SDDC Manager 為核心嗎？**
A. 不是。自 9.0 起改以 VCF Operations 為統一營運平面、VCF Automation 為自助服務平面，並引入 Fleet → Instance → Domain 階層與 VCF Identity Broker。SDDC Manager 角色轉變，VCF Installer / Fleet Management 接手大量生命週期作業。

**Q3. vRealize / Aria 套件去哪了？**
A. 已更名整併為 VCF Operations 與 VCF Automation。「SDDC Manager + vRealize Suite」是過時認知。

**Q4. 每個 Fleet 可以有幾個 VCF Operations / Automation？**
A. 各一個 —— 每個 Fleet 僅有一個 VCF Operations 實例與一個 VCF Automation 實例。

**Q5. ESX Live Patching 有什麼前提？**
A. 限 TPM-enabled 主機；修補套用於執行中 kernel memory，VM 持續運作、無維護視窗，涵蓋約 80% 修補。

**Q6. 9.1 在 API / 自動化上的最大改變是什麼？**
A. API-first：以 OpenAPI 為單一事實來源，跨 Python/Java/PowerCLI/Terraform 達成功能對等，並新增 Prometheus 相容的 Real-Time Metrics API、VGFA 與 vCenter Server Query API。

**Q7. 升級流程在哪裡查？**
A. 升級流程（5.x→9.0、9.0→9.1）與元件升級順序請參考官方升級指南；在 Claude 環境中請改用 `vcf-upgrade` skill。

**Q8. 官方那些百分比數字可以直接寫進提案嗎？**
A. 40% TCO、70% CPU、80% 修補等來自官方部落格/文件描述，正式專案請以官方文件與實際環境驗證後使用，勿當作承諾值。

---

## 10. 參考來源

- VCF 9.1 What's New: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes/what-s-new.html
- VCF 9.1 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes.html
- VCF 9.1 Bill of Materials: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes/vmware-cloud-foundation-bill-of-materials.html
- VCF 9.0 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/release-notes/vmware-cloud-foundation-90-release-notes.html
- VCF 9.0.1 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/release-notes/vmware-cloud-foundation-9-0-1-release-notes.html
- VCF 9.0.2 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/release-notes/vmware-cloud-foundation-9-0-2-release-notes.html
- VCF 9.1 公告部落格: https://blogs.vmware.com/cloud-foundation/2026/05/05/announcing-vcf-9-1-modern-private-cloud-built-for-efficiency-and-resilience/
- VCF 9.1 Programmable Infrastructure 部落格: https://blogs.vmware.com/cloud-foundation/2026/05/25/unlocking-the-full-potential-of-programmable-infrastructure-with-vmware-cloud-foundation-9-1-new-features-and-capabilities/
- VCF 9.1 Solution Brief: https://www.vmware.com/docs/vmware-cloud-foundation-9-1-solution-brief
