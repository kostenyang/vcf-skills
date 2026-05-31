# VMware Cloud Foundation 9 (9.0 / 9.1) 完整技術指南

> 本文件為可獨立閱讀的技術參考文件，內容基於 Broadcom 官方已公開之查證事實撰寫。凡未明確查證之版本號、日期、數字或行為，一律標註「以官方文件為準」。

---

## 目錄

1. [文件總覽與適用對象](#1-文件總覽與適用對象)
2. [VCF 9 的定位：Broadcom 時代的架構統一](#2-vcf-9-的定位broadcom-時代的架構統一)
3. [版本與發布資訊（9.0 / 9.1）](#3-版本與發布資訊90--91)
4. [統一平台架構（Single Platform）](#4-統一平台架構single-platform)
5. [核心元件與版本基準](#5-核心元件與版本基準)
6. [部署與安裝：VCF Installer / SDDC Manager Appliance](#6-部署與安裝vcf-installer--sddc-manager-appliance)
7. [VCF Operations：統一營運層](#7-vcf-operations統一營運層)
8. [VCF Automation：自動化與自助服務](#8-vcf-automation自動化與自助服務)
9. [Unified SDK 與 API 一致性](#9-unified-sdk-與-api-一致性)
10. [生命週期管理：vLCM Image 模式](#10-生命週期管理vlcm-image-模式)
11. [VCF 9.1 重點新功能](#11-vcf-91-重點新功能)
12. [落地三方式：Deploy / Converge / Import](#12-落地三方式deploy--converge--import)
13. [成本與 TCO 效益](#13-成本與-tco-效益)
14. [規模與上限參考表](#14-規模與上限參考表)
15. [導入規劃 Checklist](#15-導入規劃-checklist)
16. [升級與遷移 Checklist](#16-升級與遷移-checklist)
17. [常見問題（FAQ）](#17-常見問題faq)
18. [名詞對照表（Aria → VCF）](#18-名詞對照表aria--vcf)
19. [參考來源](#19-參考來源)

---

## 1. 文件總覽與適用對象

VMware Cloud Foundation 9（以下簡稱 VCF 9）是 Broadcom 收購 VMware 後，第一個進行重大架構統一的主要版本。本文件涵蓋 VCF 9.0 與 9.1 兩個版本的核心架構、元件、部署模式、生命週期管理、新功能與規劃導入要點。

適用對象：

| 角色 | 關注重點 |
|------|----------|
| 雲端 / 虛擬化架構師 | 統一平台架構、元件版本基準、落地方式 |
| 平台 / 基礎架構維運團隊 | VCF Operations、vLCM、生命週期、升級 |
| 自動化 / 平台工程團隊 | VCF Automation、Unified SDK、CaaS 自助服務 |
| AI / 高效能運算團隊 | Private AI、GPU Metrics、VKS |
| IT 決策者 / 財務 | TCO、成本效益、規模上限 |

---

## 2. VCF 9 的定位：Broadcom 時代的架構統一

VCF 9 是 Broadcom 時代第一個重大架構統一版本。其核心理念是把過去分散的多個產品（vSphere、vSAN、NSX、Aria 系列）整合為**單一平台**，由統一的生命週期（lifecycle）與營運層提供一致體驗，背後由 **VCF management services** 提供共用 runtime。

此版本同時調整了支援模式與發布節奏（release cadence），詳見官方部落格說明（見 [參考來源](#19-參考來源)）。具體的支援週期與發布時程細節以官方文件為準。

關鍵轉變：

- 由「多產品集合」走向「單一平台」。
- 統一 lifecycle 與營運層，共用 runtime。
- Aria 系列產品被整併、改名並收斂至 VCF 平台之下（VCF Operations、VCF Automation）。
- 生命週期管理全面轉向 **vLCM image**，baseline 模式不再支援。

---

## 3. 版本與發布資訊（9.0 / 9.1）

| 項目 | 內容 |
|------|------|
| VCF 9.0 GA 日期 | **2025-06-17** |
| 架構定位 | Broadcom 時代第一個重大架構統一版本 |
| 支援模式 / 發布節奏 | 已於 9 世代調整（細節以官方公告為準） |
| 9.1 發布時程 | 以官方 Release Notes 為準 |

> 注意：本文件僅明確記載已查證之 9.0 GA 日期（2025-06-17）。其他版本之確切 GA / 釋出日期，請以官方 Release Notes 為準。

---

## 4. 統一平台架構（Single Platform）

VCF 9 的核心是「單一平台」概念：

- **統一 lifecycle 與營運層**：所有核心元件的生命週期與營運由平台層統一管理，而非各產品各自為政。
- **VCF management services 提供共用 runtime**：作為平台共用的執行基礎，承載管理服務。
- **共用安裝程式**：VCF 與 VVF（vSphere Foundation）共用同一套安裝程式（VCF Installer）。

架構分層（概念示意）：

```
┌─────────────────────────────────────────────────────────┐
│  營運與自動化層                                            │
│  VCF Operations  │  VCF Automation                        │
├─────────────────────────────────────────────────────────┤
│  VCF management services（共用 runtime）                  │
│  統一 lifecycle / 統一營運                                 │
├─────────────────────────────────────────────────────────┤
│  核心元件                                                  │
│  vSphere 9 / ESX 9 / vSAN 9 / NSX 9                       │
└─────────────────────────────────────────────────────────┘
```

---

## 5. 核心元件與版本基準

VCF 9 的元件版本基準如下：

| 元件 | 版本基準 | 說明 |
|------|----------|------|
| vSphere | vSphere 9 | 計算與管理核心 |
| ESX | ESX 9 | Hypervisor（注意命名為 ESX） |
| vSAN | vSAN 9 | 軟體定義儲存 |
| NSX | NSX 9 | 軟體定義網路與安全 |

生命週期相關：

- 全面採用 **vLCM image** 模式。
- **baseline 模式不再支援**（詳見 [第 10 章](#10-生命週期管理vlcm-image-模式)）。

---

## 6. 部署與安裝：VCF Installer / SDDC Manager Appliance

### 6.1 單一 Appliance 部署

VCF 9 透過 **VCF Installer / SDDC Manager Appliance**，以單一 appliance 完成 ESX / vCenter / NSX 的部署：

- 由單一 appliance 驅動整套核心元件的部署。
- **VCF 與 VVF（vSphere Foundation）共用同一安裝程式**。
- 內建 **Quick Start App**，協助快速啟動部署流程。

### 6.2 部署特性摘要

| 特性 | 說明 |
|------|------|
| 單一 appliance | 部署 ESX / vCenter / NSX |
| 共用安裝程式 | VCF 與 VVF 共用 |
| Quick Start App | 內建，加速初始部署 |

---

## 7. VCF Operations：統一營運層

**VCF Operations 取代 Aria Operations / vROps**，作為平台的統一營運層。

重點能力：

- 接手原 Aria Operations（vRealize Operations / vROps）的營運監控職責。
- 內建**統一 storage dashboard**，可同時涵蓋 **vSAN / SAN / NAS** 多種儲存類型的可視性。

| 取代對象 | 新名稱 | 重點 |
|----------|--------|------|
| Aria Operations / vROps | VCF Operations | 統一營運；統一 storage dashboard（vSAN / SAN / NAS） |

> 在 9.1 中，VCF Operations 進一步擴充了 Private AI 相關的 GPU Metrics 可視性，詳見 [第 11 章](#11-vcf-91-重點新功能)。

---

## 8. VCF Automation：自動化與自助服務

**VCF Automation 取代 Aria Automation**，作為平台的自動化與自助服務層。

| 取代對象 | 新名稱 |
|----------|--------|
| Aria Automation | VCF Automation |

在 9.1 中，VCF Automation 與 CaaS（Container as a Service）自助服務能力進一步簡化，支援自助式 namespace（含 registry / ingress / quota / identity），詳見 [第 11 章](#11-vcf-91-重點新功能)。

---

## 9. Unified SDK 與 API 一致性

VCF 9 推出 **Unified SDK**，將原本分散的 API binding 整併：

- 整併範圍涵蓋 **vSphere / vSAN / VCF Installer / SDDC Manager** 的 API binding。
- 在 **9.1**，Unified SDK 達成跨語言一致性，支援 **Python / Java / PowerCLI / Terraform**，並以 **OpenAPI** 為基礎，確保各語言 binding 行為一致。

| 項目 | 9.0 | 9.1 |
|------|-----|-----|
| API binding 整併 | vSphere / vSAN / VCF Installer / SDDC Manager | 延續 |
| 跨語言一致性 | — | Python / Java / PowerCLI / Terraform（OpenAPI 基礎） |

---

## 10. 生命週期管理：vLCM Image 模式

VCF 9 在生命週期管理上有明確的方向轉變：

- **全面採用 vLCM image**：以 image 模式管理叢集（cluster）的元件版本與韌體。
- **baseline 不再支援**：傳統的 baseline 模式在 VCF 9 中已停止支援，現有環境若仍使用 baseline，需在規劃導入 / 升級時納入轉換考量。

實務影響：

| 面向 | 影響 |
|------|------|
| 叢集管理 | 一律以 vLCM image 定義期望狀態 |
| 既有 baseline 環境 | 需評估轉換路徑（細節以官方文件為準） |
| 升級流程 | 以 image 為基準進行並行升級（見規模上限） |

---

## 11. VCF 9.1 重點新功能

以下為 VCF 9.1 的重點新功能，數字皆來自官方查證事實。

### 11.1 規模與效能

| 項目 | 9.1 變化 |
|------|----------|
| Host 上限 | **翻倍至 5000** |
| 並行升級叢集數 | 由 **64 → 256 clusters** |
| VKS 控制平面支援 | 至 **500 clusters** |
| VKS provisioning 速度 | 約**快 70%** |

### 11.2 快速部署（Fast-Deploy）

- **VM / VKS Fast-Deploy**：採用 **linked clone** 技術，加速 VM 與 VKS 的佈建。

### 11.3 容器即服務（CaaS）自助服務

- 簡化 **CaaS 自助 namespace**，自助範圍涵蓋：
  - **registry**（映像登錄）
  - **ingress**（入口流量）
  - **quota**（資源配額）
  - **identity**（身分）

### 11.4 原生物件儲存

- **Native Object Storage（S3）**：提供原生 S3 物件儲存能力。
- 狀態：**Tech Preview**（技術預覽，正式支援程度以官方文件為準）。

### 11.5 Private AI 與 GPU 可視性

- **Private AI Model & GPU Metrics**，提供：
  - **GPU 利用率**
  - **記憶體壓力（memory pressure）**
  - **模型層級可視性（model-level visibility）**

### 11.6 記憶體與儲存效率

| 項目 | 效益 |
|------|------|
| Memory tiering | 約省 **40%** server 成本 |
| 壓縮去重（compression / dedup）儲存 | TCO 約降 **39%** |
| Kubernetes 營運成本 | 約降 **46%** |

### 11.7 網路

- **Unified EVPN**：支援 **Arista / Cisco / SONiC**。

### 11.8 9.1 新功能總表

| 分類 | 功能 | 重點數字 / 狀態 |
|------|------|-----------------|
| 規模 | Host 上限 | 5000 |
| 規模 | 並行升級叢集 | 64 → 256 |
| 規模 | VKS 控制平面 | 至 500 clusters |
| 效能 | VKS provisioning | 約快 70% |
| 效能 | VM / VKS Fast-Deploy | linked clone |
| CaaS | 自助 namespace | registry / ingress / quota / identity |
| 儲存 | Native Object Storage（S3） | Tech Preview |
| AI | Private AI Model & GPU Metrics | GPU 利用率 / 記憶體壓力 / 模型層級可視性 |
| 成本 | Memory tiering | 約省 40% server 成本 |
| 成本 | 壓縮去重儲存 | TCO 約降 39% |
| 成本 | K8s 營運成本 | 約降 46% |
| 網路 | Unified EVPN | Arista / Cisco / SONiC |

---

## 12. 落地三方式：Deploy / Converge / Import

VCF 9 提供三種落地（導入）方式：

| 方式 | 說明 | 適用情境 |
|------|------|----------|
| **Deploy** | 全新部署 | 綠地（greenfield）全新環境建置 |
| **Converge** | 收斂現有環境 | 將現有環境收斂進 VCF 平台管理 |
| **Import** | 匯入現有環境 | 將既有環境匯入納管 |

> 三種方式的詳細前置條件、限制與步驟，以官方文件為準。

選擇建議（一般原則）：

- 沒有既有環境、要從零建置 → **Deploy**
- 有既有環境、希望逐步收斂納入統一管理 → **Converge**
- 有既有環境、希望直接匯入納管 → **Import**

---

## 13. 成本與 TCO 效益

VCF 9.1 在成本面提出以下可量化效益（數字依官方查證事實）：

| 效益項目 | 幅度 | 來源機制 |
|----------|------|----------|
| Server 成本 | 約省 **40%** | Memory tiering |
| 儲存 TCO | 約降 **39%** | 壓縮去重（compression / dedup） |
| Kubernetes 營運成本 | 約降 **46%** | VKS / CaaS 平台化營運 |

> 上述為官方提出之效益參考值，實際結果依環境、工作負載與配置而異，最終以官方文件與實測為準。

---

## 14. 規模與上限參考表

| 項目 | 數值 | 版本 |
|------|------|------|
| Host 上限 | 5000 | 9.1 |
| 並行升級叢集數 | 256（由 64 提升） | 9.1 |
| VKS 控制平面支援叢集數 | 500 | 9.1 |
| VKS provisioning 速度提升 | 約 70% | 9.1 |

> 其他未列出之組態上限（configuration maximums），請以官方 Configuration Maximums 文件為準。

---

## 15. 導入規劃 Checklist

規劃 VCF 9 導入時，建議逐項確認：

- [ ] 確認目標版本（9.0 或 9.1）與其官方支援週期（以官方文件為準）
- [ ] 確認核心元件版本基準：vSphere 9 / ESX 9 / vSAN 9 / NSX 9
- [ ] 確認生命週期一律使用 **vLCM image**（baseline 不再支援）
- [ ] 選定落地方式：**Deploy / Converge / Import**
- [ ] 確認是否使用 VCF Installer / SDDC Manager Appliance 單一 appliance 部署
- [ ] 確認是否使用內建 **Quick Start App**
- [ ] 規劃 **VCF Operations**（取代 Aria Operations / vROps）的營運監控
- [ ] 規劃 **VCF Automation**（取代 Aria Automation）的自動化與自助服務
- [ ] 若有自動化 / IaC 需求，規劃 **Unified SDK**（Python / Java / PowerCLI / Terraform）
- [ ] 若有容器需求，規劃 **VKS** 與 **CaaS 自助 namespace**（registry / ingress / quota / identity）
- [ ] 若有 AI 工作負載，規劃 **Private AI** 與 **GPU Metrics**
- [ ] 評估 **memory tiering** 與 **壓縮去重** 的成本效益
- [ ] 若有 EVPN 網路需求，確認 **Unified EVPN**（Arista / Cisco / SONiC）相容性
- [ ] 評估是否啟用 **Native Object Storage（S3）**（注意為 Tech Preview）
- [ ] 確認規模需求是否落在上限內（host 5000 / VKS 500 clusters 等）

---

## 16. 升級與遷移 Checklist

- [ ] 盤點現有環境是否使用 **baseline** 模式（VCF 9 不再支援，需轉換為 vLCM image）
- [ ] 盤點現有 Aria Operations / vROps 與 Aria Automation 部署，規劃轉換至 VCF Operations / VCF Automation
- [ ] 確認既有環境採用 **Converge** 或 **Import** 的適用性與前置條件（以官方文件為準）
- [ ] 規劃並行升級策略（9.1 支援並行升級至 256 clusters）
- [ ] 確認升級後元件版本基準符合 vSphere 9 / ESX 9 / vSAN 9 / NSX 9
- [ ] 確認既有自動化腳本 / API 整合是否需配合 Unified SDK 調整
- [ ] 規劃升級維護視窗與回復（rollback）策略（細節以官方文件為準）
- [ ] 確認儲存（vSAN / SAN / NAS）在 VCF Operations 統一 dashboard 的納管狀態
- [ ] 升級後驗證統一 storage dashboard 與 GPU Metrics（若適用）可視性

---

## 17. 常見問題（FAQ）

**Q1：VCF 9 和過去最大的差異是什麼？**
A：VCF 9 是 Broadcom 時代第一個重大架構統一版本，由「多產品集合」走向「單一平台」，統一 lifecycle 與營運層，並由 VCF management services 提供共用 runtime。

**Q2：Aria 系列產品到哪去了？**
A：Aria Operations / vROps 被 **VCF Operations** 取代；Aria Automation 被 **VCF Automation** 取代。

**Q3：還能用 baseline 管理叢集嗎？**
A：不行。VCF 9 全面採用 **vLCM image**，**baseline 不再支援**。

**Q4：VCF 與 VVF（vSphere Foundation）的安裝程式一樣嗎？**
A：是。兩者共用同一套 VCF Installer，並內建 Quick Start App。

**Q5：Native Object Storage（S3）可以正式上線使用嗎？**
A：在 9.1 中為 **Tech Preview**（技術預覽），是否可用於正式環境以官方文件為準。

**Q6：9.1 的成本效益數字是保證值嗎？**
A：否。約省 40% server 成本、儲存 TCO 約降 39%、K8s 營運成本約降 46% 為官方提出之效益參考值，實際依環境而異。

---

## 18. 名詞對照表（Aria → VCF）

| 舊名稱 | VCF 9 新名稱 | 角色 |
|--------|--------------|------|
| Aria Operations / vRealize Operations / vROps | VCF Operations | 統一營運與監控 |
| Aria Automation | VCF Automation | 自動化與自助服務 |
| 各產品分散 API binding | Unified SDK | 統一 API binding（OpenAPI 基礎） |
| baseline（生命週期） | vLCM image | 叢集生命週期管理 |

---

## 19. 參考來源

1. VMware Cloud Foundation 9.0 and later — Broadcom TechDocs
   https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0.html
2. What's New in VMware Cloud Foundation 9.0 — Solution Brief
   https://www.vmware.com/docs/whats-new-in-vmware-cloud-foundation-9-0-solution-brief
3. VMware Cloud Foundation 9.1.0.0 Release Notes — What's New — Broadcom TechDocs
   https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes/what-s-new.html
4. VMware Cloud Foundation 9.1 — Solution Brief
   https://www.vmware.com/docs/vmware-cloud-foundation-9-1-solution-brief
5. VMware Cloud Foundation 9 Ushers in New Support Model and Release Cadence — VMware Cloud Foundation Blog
   https://blogs.vmware.com/cloud-foundation/2025/07/16/vmware-cloud-foundation-9-ushers-in-new-support-model-and-release-cadence/
