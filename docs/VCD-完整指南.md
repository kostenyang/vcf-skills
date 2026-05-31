# VMware Cloud Director (VCD 10.6 系列) 完整技術指南

> 本文件為可獨立閱讀之技術參考文件，全程以繁體中文撰寫，技術名詞保留英文。所有版本號、build 號與功能描述均依據文末「參考來源」之官方資料 (以 Broadcom TechDocs Release Notes 為準)；凡屬不確定之細節，皆標註「以官方文件為準」。
>
> 涵蓋版本：VCD 10.6 (GA 27 JUN 2024)、10.6.1 (31 JAN 2025)，以及目前最新修補版 **10.6.1.2 (05 DEC 2025)**。

---

## 目錄

1. [文件目的與適用對象](#1-文件目的與適用對象)
2. [VCD 平台概述與交付模式](#2-vcd-平台概述與交付模式)
3. [版本譜系與 Build 號](#3-版本譜系與-build-號)
4. [資源層級架構 (Resource Hierarchy)](#4-資源層級架構-resource-hierarchy)
5. [Org VDC 配置模型 (Allocation Models)](#5-org-vdc-配置模型-allocation-models)
6. [網路與 Edge Gateway](#6-網路與-edge-gateway)
7. [IP 管理：IP Spaces、IP Retention 與 Data Center Group](#7-ip-管理ip-spacesip-retention-與-data-center-group)
8. [Catalog 內容管理與 Global / Distributed Catalogs](#8-catalog-內容管理與-global--distributed-catalogs)
9. [Multi-Tier Tenancy 三層租戶](#9-multi-tier-tenancy-三層租戶)
10. [Kubernetes 整合與細粒度授權](#10-kubernetes-整合與細粒度授權)
11. [Guest OS-Aware VM Placement (VM 放置與合規)](#11-guest-os-aware-vm-placement-vm-放置與合規)
12. [安全：API Token 治理與防火牆授權控管](#12-安全api-token-治理與防火牆授權控管)
13. [10.6 / 10.6.1 / 10.6.1.2 新功能與修復總覽](#13-106--1061--10612-新功能與修復總覽)
14. [部署與營運 Checklist](#14-部署與營運-checklist)
15. [常見使用情境 (Use Cases)](#15-常見使用情境-use-cases)
16. [FAQ 常見問題](#16-faq-常見問題)
17. [名詞對照表 (Glossary)](#17-名詞對照表-glossary)
18. [參考來源](#18-參考來源)

---

## 1. 文件目的與適用對象

本指南針對 **VMware Cloud Director (VCD) 10.6 系列**，說明其平台定位、交付模式、版本譜系、資源架構、配置模型，以及各版本所導入的新功能與修復。

適用對象：

| 角色 | 關注重點 |
| --- | --- |
| VMware Cloud Service Provider (VCSP) | 多租戶 IaaS 交付、計費模型、內容散佈、VCF 授權 |
| 電信業 / VCSP | 多租戶網路、IP Spaces、BGP、NSX/Avi 整合 |
| 大型企業 / MSP 架構師 | 分層委派、租戶隔離、合規放置 |
| 平台維運工程師 | Edge Gateway、網路、Catalog、Kubernetes、升級 |
| 安全與合規團隊 | API Token 管理、防火牆授權、VM 合規放置 |

---

## 2. VCD 平台概述與交付模式

VMware Cloud Director (VCD) 是 **Broadcom (前 VMware)** 的多租戶雲服務交付平台，主要供 **VMware Cloud Service Provider (VCSP)**、**電信業**與**企業私有雲**，在底層 VMware 基礎架構 (vCenter、NSX、儲存) 之上，抽象出一套以「租戶 (tenant)」為中心的資源消費模型，讓單一實體基礎架構能安全地切分給多個組織使用，並提供自助式 (self-service) 入口、API 與內容管理能力。

**交付模式更新**：VCD 現以「**VMware Cloud Foundation (VCF) 方案的一部分**」交付 — 10.6.1 即明確標示為 "as part of the VCF offering"，不再是獨立 VMware 產品線。研究 VCSP 商業模式或授權時應據此更新。

VCD 的核心價值：

- **多租戶隔離**：在共用基礎架構上提供邏輯隔離的租戶環境。
- **資源切片與配額**：將實體資源切分為可計量、可配額的單位交付給租戶。
- **自助服務與 API 驅動**：租戶可透過 UI 或 API 自行佈建 vApp/VM/網路。
- **內容交付**：透過 Catalog 管理與散佈 vApp Template、ISO 等內容。
- **分層委派**：透過三層租戶模型 (Provider → Sub-Provider → Managed Org) 支援轉售與企業分層治理。

---

## 3. 版本譜系與 Build 號

VCD 10.6 系列**目前最新版為修補版 10.6.1.2**，並非 10.6.1。以下版本日期與 build 號皆來自官方 Release Notes。

| 版本 | GA / 釋出日期 | Build (installed build) | 性質 |
| --- | --- | --- | --- |
| 10.6 | 27 JUN 2024 | 24055916 (24055813) | GA |
| 10.6.0.1 | 修補版 | — | 維護性修補 |
| 10.6.1 | 31 JAN 2025 | 24532678 (24532667) | 新功能釋出，as part of the VCF offering |
| 10.6.1.1 | 修補版 | — | 維護性修補 |
| **10.6.1.2** | **05 DEC 2025** | **25088252 (25086345)** | **目前最新**，維護性釋出 |

重要提醒：

- 10.6.1.2 屬維護性釋出 (bug fixes + appliance base OS / 開源元件更新，約 50+ 已解決問題)，**無新功能特性**。
- **日期警示**：部分第三方追蹤站 (virten.net vTracker、搜尋摘要) 對 10.6.1.2 出現「2024-12-05」與 build 號互換的錯誤標示。官方 TechDocs Release Notes 標示為 **05 DEC 2025**，版本日期一律以官方為準。
- **10.6.2**：本研究於官方 TechDocs 未找到 10.6.2 的獨立 Release Notes 或 GA 資訊，最高僅到 10.6.1.2 修補線。若聲稱已有 10.6.2 GA 屬未經證實，以官方文件為準。

---

## 4. 資源層級架構 (Resource Hierarchy)

VCD 以階層方式組織資源，由 Provider 端逐層向下切分至租戶可消費的單位。

### 4.1 層級結構

```
System (Provider)
   └── Provider VDC (PVDC)      ── 對應 vCenter resource pool + 儲存 + NSX
          └── Organization (租戶)
                 └── Org VDC    ── 資源切片，套用配額
                        └── vApp / VM / Network / Edge Gateway
```

### 4.2 各層級說明

| 層級 | 角色 | 對應底層資源 | 說明 |
| --- | --- | --- | --- |
| **System (Provider)** | 平台最上層管理範圍 | 整體 VMware 基礎架構 | Provider 管理員操作的全域範圍 |
| **Provider VDC (PVDC)** | Provider 端資源池 | vCenter resource pool + 儲存 + NSX | 將實體運算、儲存、網路資源納入 VCD 管理 |
| **Organization (Org)** | 租戶 | — | 一個獨立的租戶單位，含使用者、角色、政策、目錄 |
| **Org VDC** | 租戶資源切片 | 由 PVDC 切分而來 | 套用配額 (quota) 與配置模型，租戶實際消費資源之處 |
| **vApp / VM** | 工作負載 | VM / 應用群組 | 租戶部署的虛擬機與應用 |
| **Network / Edge Gateway** | 租戶網路 | NSX 網路服務 | 租戶網路與邊界閘道服務 |

> PVDC 對應 vCenter resource pool、儲存與 NSX；Org VDC 為自 PVDC 切分出的資源切片並套用配額。具體支援的 vCenter / NSX 版本相容性以官方文件為準。

### 4.3 規模上限 (10.6 GA 提升)

| 項目 | 上限 |
| --- | --- |
| VM | 55,000 |
| 並發遠端主控台 (concurrent remote consoles) | 22,000 |
| 最大使用者數 | 300,000 |
| 群組內 Organization VDC | 2,000 |

---

## 5. Org VDC 配置模型 (Allocation Models)

Org VDC 決定資源如何自 PVDC 配置給租戶。VCD 提供下列配置模型：

| 配置模型 | 說明 | 適用情境 |
| --- | --- | --- |
| **Allocation Pool** | 配置一個資源池，可設定保證 (guaranteed) 百分比 | 需可預期容量但保留彈性的租戶 |
| **Pay-As-You-Go** | 依實際使用量計算，無預先保留 | 用量浮動、按使用計費 |
| **Reservation Pool** | 完全保留 (reserved) 資源給租戶，租戶可自行超分 | 需要穩定且專屬效能的關鍵負載 |
| **Flex** | 彈性混合配置模型 (10.x 主推) | 需要在單一模型下混合不同配置策略 |

> 各模型的保證百分比、超賣 (overcommit) 行為與計費細節，請以官方文件為準。注意 10.6.1.2 修復了 flex allocation model 相關的 VM 開機失敗問題。

---

## 6. 網路與 Edge Gateway

### 6.1 Edge Gateway

在 VCD 中，**Edge Gateway 由 NSX 提供**，作為租戶網路的邊界閘道，提供下列服務：

| 服務 | 說明 |
| --- | --- |
| **NAT** | 網路位址轉換 |
| **FW (Firewall)** | 防火牆規則 (T0 / T1) |
| **LB (Load Balancer)** | 負載平衡 (整合 VMware Avi Load Balancer) |
| **VPN** | IPsec VPN / L2 VPN |

### 6.2 Org VDC Network 與 Data Center Group

- **Org VDC Network**：Routed / Isolated / Imported。
- **Data Center Group**：跨多個 Org VDC 共用 NSX 網路與分散式防火牆 (DFW)。

### 6.3 10.6.1 網路強化

- **Gateway Firewall 強制狀態可視性**：對 T1 與 T0 防火牆的 enforcement status 有完整可視性，並具管理員覆寫能力。
- **Stateful Firewall 存取控管**：供應商可限制租戶在未取得 ANS (Advanced Network Security / 安全堆疊) 授權時新增防火牆規則。
- **可分享的自訂 Segment Profile**：供應商可將自訂網路 segment profile 範本散佈 / 複製給租戶組織或跨多個 NSX projects，以標準化組態。
- **IPv6 Transparent Load Balancing**：恢復對 VMware Avi Load Balancer 的 IPv6 支援，pool members 可看到 client 的來源 IP。

> Edge Gateway 的規模 (form factor)、各服務的詳細功能與上限，請以官方文件為準。

---

## 7. IP 管理：IP Spaces、IP Retention 與 Data Center Group

### 7.1 IP Spaces

**IP Spaces** 是 VCD 的 **IP 配置 / 追蹤系統**，提供集中化的 IP 位址管理。重點事實：

- 由一組**不重疊**的 IP ranges 與小型 CIDR blocks 構成。
- 一個 IP space **只能是 IPv4 或 IPv6，不可混用**。
- **Private IP Space**：專屬單一租戶 (建立時指定的組織)，對該組織的 IP 消耗不受限。
- **Shared / 共享 IP 池**：供應商可建立共享 IP 位址池供租戶在配額內 **draw down**；配額可全域設定，並可對個別租戶**覆寫 (override)**。
- **對齊三層模型**：IP Spaces / IPsec VPN 管理對齊 tenant、sub-provider、provider 三種角色，皆可管理 IP 生命週期與設定 VPN。
- **BGP 整合**：可用 BGP 控制哪些 IP prefix 走 VPN；當供應商以 IP Spaces 管理公私網位址時，可自動化租戶的 BGP 設定。

> IP Spaces 概念最早於 VCD 10.4.1 引入，本指南確認其在 10.6 已對齊三層權限模型。

### 7.2 IP Retention (自訂 IP 保留期) — 10.6.1

**Custom IP Retention** 允許在 **sub-provider / managed org 層級**自訂 **IP 保留期間**：

- 即使 **VM 被刪除或 NIC 被移除**，IP 仍會在設定的保留期內被保留。
- 避免位址立即釋放造成的重複配發或追蹤困難。

### 7.3 Data Center Group

**Data Center Group** 讓多個 **Org VDC** 之間能**共用 NSX 網路與 DFW (Distributed Firewall)**：

- 跨 Org VDC 共用網路與分散式防火牆政策。
- 適用於需要跨資源切片統一網路與安全政策的情境。

> IP 保留期的最大值、IP Spaces 與 Data Center Group 的詳細上限與相依條件，請以官方文件為準。

---

## 8. Catalog 內容管理與 Global / Distributed Catalogs

**Catalog** 為 vApp Template、Template 與 ISO 的內容庫，是 VCD 中內容散佈與標準化交付的核心機制。

| 內容類型 | 用途 |
| --- | --- |
| **vApp Template** | 預先打包的 vApp/VM 範本，供快速部署 |
| **Template** | VM 範本 |
| **ISO** | 安裝媒體 / 映像檔 |

Catalog 支援 **published / subscribed** 訂閱模型，可供租戶內部使用，亦可在多個租戶或多個 instance 間共享。

### 8.1 Global / Distributed Catalogs (10.6 GA)

VCD 10.6 導入 **Global / Distributed Catalogs**：

- 可建立並發佈**跨多個 vCenter 執行個體、跨多個 VCD 站點皆一致**的目錄。
- 透過共享儲存 / 複寫技術維持一致性，降低各區域各自維護內容造成的版本不一致問題。

| 情境 | 價值 |
| --- | --- |
| 多區域 VCSP | 一次發佈，全區域可用 |
| 多 instance 企業環境 | 內容版本一致性 |
| 災難復原 / 多站點 | 內容於多站點間維持可用 |

> Global / Distributed Catalogs 的同步機制、頻率與相依元件，請以官方文件為準。

---

## 9. Multi-Tier Tenancy 三層租戶

VCD 10.6 GA 導入 **Three-Tier / Multi-Tier Tenancy (三層租戶)**，將傳統的兩層 (Provider → Org) 模型擴充為三層。雲供應商可建立 sub-provider 組織，對一組受限的租戶具有**受限管理權限**。

```
Provider (System)
   └── Sub-Provider
          └── Managed Org / Tenant
```

### 9.1 角色與委派

| 層級 | 角色定位 | 典型對象 |
| --- | --- | --- |
| **Provider** | 平台擁有者，最高管理權 | VCSP / 電信 / 企業中央 IT |
| **Sub-Provider** | 受委派的中間層，對一組受限租戶有受限管理權 | MSP / 經銷商 / 事業群 / 區域團隊 |
| **Managed Org / Tenant** | 最終租戶 | 終端客戶 / 部門 |

### 9.2 適用情境

- **MSP (Managed Service Provider)**：VCSP 將一部分管理權委派給 MSP，由 MSP 再服務其終端客戶。
- **企業分層委派**：企業中央 IT 將管理權下放給事業群或區域團隊 (總部 → 子公司 → BU)。

> 各層可委派的具體權限範圍與限制，請以官方文件為準。

---

## 10. Kubernetes 整合與細粒度授權

### 10.1 CSE (Container Service Extension)

**CSE (Container Service Extension)** 為 VCD 提供 **Kubernetes (Tanzu / TKG) 叢集的自助佈建 (self-service provisioning)** 能力，讓租戶可在 VCD 內自行建立與管理 K8s 叢集。

### 10.2 容器存取控管與細粒度授權 (10.6 GA)

- Kubernetes 叢集管理員可控管 **tenant 使用者對叢集 / namespace 的存取**。
- 支援**多使用者共用同一叢集**，各自於專屬 **namespace** 部署工作負載。
- 可**檢視容器應用的修訂歷史**。

| 授權層級 | 控制範圍 | 效果 |
| --- | --- | --- |
| **Cluster 層級** | 整個 K8s 叢集 | 使用者可存取整個叢集 |
| **Namespace 層級** | 個別 namespace | 使用者僅能存取被授權的 namespace |

此能力讓「多租戶 / 多使用者共用叢集」成為可行的營運模式，在降低叢集數量的同時維持隔離。

> CSE 版本相容性、支援的 Kubernetes 版本與 runtime，請以官方文件為準。

---

## 11. Guest OS-Aware VM Placement (VM 放置與合規)

VCD 10.6.1 提供以 **guest OS** 為依據的 **VM 放置 (placement) 與合規 (compliance)** 控制：

- 管理員可為**特定 OS 類型**定義 **VM Groups**。
- 將 VM Group 放置至**指定的 host 或 cluster**，以符合**合規與授權需求** (例如 Microsoft 授權需求)。
- 跨所有租戶套用。

### 11.1 典型應用

| 需求 | 作法 |
| --- | --- |
| 授權合規 (例如特定 OS 須綁定特定實體主機) | 將該 guest OS 的 VM Group 綁定至特定 host/cluster |
| 效能 / 隔離需求 | 將特定工作負載放置至專屬 cluster |
| 法規 / 資料落地 | 將 VM 限制於符合規範的硬體範圍內 |

> VM Group 與 host/cluster 對應的設定方式及限制，請以官方文件為準。

---

## 12. 安全：API Token 治理與防火牆授權控管

### 12.1 強制 API Token 到期與即時失效 (10.6.1)

- 管理員可**強制 API token 到期 (force expiration)**。
- 可**即時失效 (instantly invalidate)** API token，以因應安全或管理變更。
- 提升 token 生命週期管理與安全治理能力，降低長期有效 token 的外洩風險。

### 12.2 Stateful Firewall 授權控管 (10.6.1)

- 供應商可限制租戶在**未取得 ANS (Advanced Network Security / 安全堆疊) 授權**時新增防火牆規則。

### 12.3 安全治理建議 (Checklist)

- [ ] 為 API Token 設定合理的到期 / 撤銷政策。
- [ ] 對外洩或離職人員相關 token 立即執行即時失效。
- [ ] 定期稽核有效 token 清單。
- [ ] 結合租戶角色與權限 (RBAC) 控制 token 可操作範圍。
- [ ] 依授權狀態 (ANS) 控管租戶防火牆規則新增權限。
- [ ] 注意 10.6 已解決 CVE-2024-22272；維持升級至最新修補版。

> 各功能的具體設定路徑與政策選項，請以官方文件為準。

---

## 13. 10.6 / 10.6.1 / 10.6.1.2 新功能與修復總覽

### 13.1 10.6 GA (27 JUN 2024) 重點

| 功能 | 摘要 |
| --- | --- |
| **Three-Tier Tenancy** | Provider → Sub-Provider → Managed Org 三層委派 |
| **Global / Distributed Catalogs** | 跨多 vCenter / 多 VCD 站點一致的目錄 |
| **每 VM 多重快照** | 每台 VM 多個快照，上限由供應商設定 |
| **IPv6 cell 支援** | appliance cells 可運行於 IPv6 環境 |
| **容器存取控管與修訂歷史** | 控管 tenant 對叢集 / namespace 存取 |
| **規模上限大增** | VM 55,000 / 使用者 300,000 / 主控台 22,000 / OrgVDC 2,000 |
| **Photon OS 4.0 appliance** | 安全性與 OS 套件升級 |
| **PostgreSQL 13+** | 外部資料庫需求提升 |
| **CVE-2024-22272** | 安全修復 |

### 13.2 10.6.1 (31 JAN 2025) 新功能

| 功能 | 摘要 |
| --- | --- |
| **Guest OS-Aware VM Placement** | 依 guest OS 以 VM Groups 放置至特定 host/cluster，符合授權合規 |
| **API Token 強制到期 / 即時失效** | 提升存取治理 |
| **Custom IP Retention** | sub-provider / managed org 層級自訂 IP 保留期 |
| **Gateway Firewall enforcement 可視性** | T0/T1 完整可視性與管理員覆寫 |
| **Stateful Firewall 授權控管** | 未具 ANS 授權租戶無法新增防火牆規則 |
| **可分享 Segment Profile** | 跨 NSX projects 複製標準化組態 |
| **IPv6 Transparent LB** | 恢復 Avi Load Balancer IPv6 支援，pool members 可見 client 來源 IP |
| 其他 | 更新 Custom Task API、修復 Virtual Data Centers 檢視、移除舊版 NSX MP API 參照 |

### 13.3 10.6.1.2 (05 DEC 2025) 代表性修復

維護性釋出，約 50+ 已解決問題，無新功能。代表性修復：

- VM 頁面快照儲存值顯示錯誤。
- flex allocation model 相關的 VM 開機失敗。
- 組織 IP spaces 配額修改問題。
- SAML 以 NameID 對應 email 的問題。
- RabbitMQ 事件處理失敗。
- vSAN datastore 上儲存原則 relocation 錯誤。
- guest customization 設定失敗。
- 資料庫升級 constraint violation。
- NSX edge gateway 在第 129+ 位置編輯 IPsec VPN tunnel 的問題。

---

## 14. 部署與營運 Checklist

### 14.1 規劃階段

- [ ] 確認目標版本與 build (現最高 **10.6.1.2 / Build 25088252，05 DEC 2025**) 及與底層 vCenter、NSX 的版本相容性 (以官方文件為準)。
- [ ] 確認外部資料庫為 **PostgreSQL 13 或更新版本**。
- [ ] 規劃 PVDC 對應的 vCenter resource pool、儲存與 NSX 資源。
- [ ] 設計 Organization 與 Org VDC 切分策略與配額。
- [ ] 選定各租戶適用的配置模型 (Allocation Pool / Pay-As-You-Go / Reservation Pool / Flex)。
- [ ] 評估是否採用 Three-Tier Tenancy (Provider → Sub-Provider → Managed Org)。
- [ ] 確認 VCD 以 VCF 方案交付的授權安排。

### 14.2 網路與安全

- [ ] 規劃 Edge Gateway (NSX) 之 NAT / FW / LB / VPN 需求。
- [ ] 規劃 IP Spaces (IPv4 或 IPv6 分開、private / shared、配額與個別租戶覆寫、BGP)。
- [ ] 設定 Custom IP Retention 保留期 (sub-provider / managed org 層級)。
- [ ] 規劃 Gateway Firewall (T0/T1) enforcement 可視性與覆寫策略。
- [ ] 依 ANS 授權狀態控管租戶 Stateful Firewall 規則。
- [ ] 評估可分享 Segment Profile 標準化租戶組態。
- [ ] 規劃 Avi Load Balancer (含 IPv6 Transparent LB)。
- [ ] 評估以 Data Center Group 跨 Org VDC 共用 NSX 網路與 DFW。
- [ ] 制定 API Token 強制到期 / 即時失效政策。

### 14.3 內容與工作負載

- [ ] 建立 Catalog (vApp Template / Template / ISO)。
- [ ] 評估採用 Global / Distributed Catalogs 跨 vCenter / 站點維護內容。
- [ ] 規劃 Guest OS-Aware VM Placement (VM Group → host/cluster) 合規 / 授權政策。
- [ ] 評估每 VM 多重快照上限策略。

### 14.4 Kubernetes

- [ ] 評估部署 CSE (Container Service Extension) 提供 K8s 自助佈建。
- [ ] 設計 Kubernetes 細粒度授權 (cluster / namespace 層級)。
- [ ] 規劃多使用者共用叢集的 namespace 隔離策略。

---

## 15. 常見使用情境 (Use Cases)

| 情境 | 建議採用的 VCD 能力 |
| --- | --- |
| VCSP / 電信對外提供多租戶 IaaS | 完整資源層級 + 配置模型 + Edge Gateway + Catalog |
| MSP 分層轉售 | Three-Tier Tenancy (Provider → Sub-Provider → Managed Org) |
| 企業內部分層委派 | Three-Tier Tenancy + RBAC |
| 多租戶 / 多使用者共用 K8s | CSE + Kubernetes namespace 細粒度授權 |
| 授權合規 / 資料落地 | Guest OS-Aware VM Placement (VM Group → host/cluster) |
| 集中化 IP 治理 + 自動化 BGP | IP Spaces (private/shared、配額覆寫、BGP) + IP Retention |
| 跨 Org VDC 統一網路與安全 | Data Center Group (共用 NSX 網路 + DFW) |
| 多 vCenter / 多站點內容一致性 | Global / Distributed Catalogs |
| API 安全治理 | API Token 強制到期 / 即時失效 |
| 租戶防火牆分級服務 | Stateful Firewall + ANS 授權控管 + Gateway Firewall 可視性 |

---

## 16. FAQ 常見問題

**Q1. VCD 10.6 系列目前最新版是哪一版？**
A. 是修補版 **10.6.1.2 (05 DEC 2025，Build 25088252 / installed build 25086345)**，不是 10.6.1。10.6.1 GA 為 31 JAN 2025。

**Q2. 有沒有 10.6.2？**
A. 本研究在官方 TechDocs 未找到 10.6.2 的獨立 Release Notes 或 GA 資訊，最高僅到 10.6.1.2 修補線。是否有 10.6.2 以官方文件為準。

**Q3. 為什麼有資料寫 10.6.1.2 是 2024-12-05？**
A. 那是部分第三方追蹤站 (virten.net 等) 將「2024-12-05」與 build 號互換的錯誤標示。官方 TechDocs Release Notes 寫的是 **05 DEC 2025**，版本日期一律以官方為準。

**Q4. VCD 還是獨立產品嗎？如何取得授權？**
A. VCD 現以 **VMware Cloud Foundation (VCF) 方案的一部分**交付 (10.6.1 即 "as part of the VCF offering")，不再是獨立 VMware 產品線。

**Q5. 10.6.1.2 有什麼新功能？**
A. 沒有新功能。它是維護性釋出 (bug fixes + appliance base OS / 開源元件更新，約 50+ 已解決問題)。最新一輪新功能來自 10.6.1。

**Q6. 外部資料庫要求是什麼？**
A. 10.6 起外部資料庫需 **PostgreSQL 13 或更新版本**。

**Q7. 三層租戶是什麼時候導入的？**
A. **10.6 GA (27 JUN 2024)** 導入 Three-Tier Tenancy；供應商可建立 sub-provider，對一組受限租戶有受限管理權。

**Q8. IP Spaces 可以混用 IPv4 與 IPv6 嗎？**
A. 不行。一個 IP space **只能是 IPv4 或 IPv6**，由一組不重疊的 IP ranges 與 CIDR blocks 構成。

**Q9. VM 刪除後 IP 會立刻釋放嗎？**
A. 若設定 Custom IP Retention (10.6.1，sub-provider / managed org 層級)，即使 VM 刪除或 NIC 移除，IP 仍在保留期內被保留。

---

## 17. 名詞對照表 (Glossary)

| 縮寫 / 名詞 | 全名 / 說明 |
| --- | --- |
| **VCD** | VMware Cloud Director |
| **VCF** | VMware Cloud Foundation (VCD 現以其方案交付) |
| **VCSP** | VMware Cloud Service Provider |
| **MSP** | Managed Service Provider |
| **IaaS** | Infrastructure as a Service |
| **PVDC** | Provider VDC (Provider Virtual Data Center) |
| **Org VDC** | Organization Virtual Data Center |
| **Sub-Provider** | 三層租戶中間層，對受限租戶有受限管理權 |
| **Managed Org** | 三層租戶中受管的最終租戶 |
| **vApp** | 虛擬應用 (一組 VM 與其關係的封裝) |
| **Edge Gateway** | 租戶網路邊界閘道 (由 NSX 提供) |
| **IP Spaces** | 集中化 IP 配置 / 追蹤系統 (單一 space 只能 IPv4 或 IPv6) |
| **ANS** | Advanced Network Security (進階網路安全堆疊授權) |
| **NAT / FW / LB / VPN** | Network Address Translation / Firewall / Load Balancer / Virtual Private Network |
| **DFW** | Distributed Firewall |
| **T0 / T1** | NSX Tier-0 / Tier-1 Gateway |
| **BGP** | Border Gateway Protocol |
| **Avi** | VMware Avi Load Balancer |
| **Catalog** | vApp Template / Template / ISO 內容庫 |
| **CSE** | Container Service Extension |
| **TKG** | Tanzu Kubernetes Grid |
| **DHCP** | Dynamic Host Configuration Protocol |
| **RBAC** | Role-Based Access Control |
| **Photon OS** | VCD appliance base OS (10.6 為 4.0) |

---

## 18. 參考來源

- VMware Cloud Director 10.6 Release Notes — Broadcom TechDocs
  https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-106-release-notes.html
- VMware Cloud Director 10.6.1 Release Notes — Broadcom TechDocs
  https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-1061-release-notes.html
- VMware Cloud Director 10.6.1.2 Release Notes — Broadcom TechDocs
  https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-10612-release-notes.html
- VMware Cloud Director 10.6 Release Notes 總覽 — Broadcom TechDocs
  https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes.html
- VMware Cloud Director 10.6.1 Is Here — What's New (VMware Cloud Provider Blog, 2025-02)
  https://blogs.vmware.com/cloudprovider/2025/02/vmware-cloud-director-10-6-1-is-here-whats-new.html
- Working with IP Spaces (VCD 10.6 Tenant Portal Guide) — Broadcom TechDocs
  https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/map-for-vmware-cloud-director-tenant-portal-guide-10-6/working-with-networks-tenant/working-with-ip-spaces-tenant.html
- Build numbers and installer versions of VMware Cloud Director (Broadcom KB 325479)
  https://knowledge.broadcom.com/external/article/325479/build-numbers-and-installer-versions-of.html
- VMware Product Release Tracker (virten.net，第三方；日期須與官方核對)
  https://www.virten.net/vmware/product-release-tracker/
