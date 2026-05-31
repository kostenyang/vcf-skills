# VMware Cloud Director (VCD 10.6 / 10.6.1) 完整技術指南

> 本文件為可獨立閱讀之技術參考文件，全程以繁體中文撰寫，技術名詞保留英文。所有版本號、功能描述均依據文末「參考來源」之官方資料；凡屬不確定之細節，皆標註「以官方文件為準」。

---

## 目錄

1. [文件目的與適用對象](#1-文件目的與適用對象)
2. [VCD 平台概述](#2-vcd-平台概述)
3. [資源層級架構 (Resource Hierarchy)](#3-資源層級架構-resource-hierarchy)
4. [Org VDC 配置模型 (Allocation Models)](#4-org-vdc-配置模型-allocation-models)
5. [網路與 Edge Gateway](#5-網路與-edge-gateway)
6. [Catalog 內容管理](#6-catalog-內容管理)
7. [10.6 / 10.6.1 新功能總覽](#7-106--1061-新功能總覽)
8. [Multi-Tier Tenancy 三層租戶](#8-multi-tier-tenancy-三層租戶)
9. [Kubernetes 整合與細粒度授權](#9-kubernetes-整合與細粒度授權)
10. [VM 放置與合規 (VM Placement & Compliance)](#10-vm-放置與合規-vm-placement--compliance)
11. [IP 管理：IP Spaces、IP Retention 與 Data Center Group](#11-ip-管理ip-spacesip-retention-與-data-center-group)
12. [安全：API Token 強制過期與存取控制](#12-安全api-token-強制過期與存取控制)
13. [Global Distributed Catalogs](#13-global-distributed-catalogs)
14. [部署與營運 Checklist](#14-部署與營運-checklist)
15. [常見使用情境 (Use Cases)](#15-常見使用情境-use-cases)
16. [名詞對照表 (Glossary)](#16-名詞對照表-glossary)
17. [參考來源](#17-參考來源)

---

## 1. 文件目的與適用對象

本指南針對 **VMware Cloud Director (VCD) 10.6 與 10.6.1** 版本，說明其平台定位、資源架構、配置模型，以及這兩個版本所導入的新功能。

適用對象：

| 角色 | 關注重點 |
| --- | --- |
| VMware Cloud Service Provider (VCSP) | 多租戶 IaaS 交付、計費模型、內容散佈 |
| 大型企業 / MSP 架構師 | 分層委派、租戶隔離、合規放置 |
| 平台維運工程師 | Edge Gateway、網路、Catalog、Kubernetes 維運 |
| 安全與合規團隊 | API Token 管理、存取控制、VM 合規放置 |

---

## 2. VCD 平台概述

VMware Cloud Director (VCD) 是供 **VMware Cloud Service Provider (VCSP)** 與**大型企業**建構**多租戶 (multi-tenant) IaaS** 的**管理與交付平台**。它在底層 VMware 基礎架構 (vCenter、NSX、儲存) 之上，抽象出一套以「租戶 (tenant)」為中心的資源消費模型，讓單一實體基礎架構能安全地切分給多個組織使用，並提供自助式 (self-service) 入口、API 與內容管理能力。

VCD 的核心價值：

- **多租戶隔離**：在共用基礎架構上提供邏輯隔離的租戶環境。
- **資源切片與配額**：將實體資源切分為可計量、可配額的單位交付給租戶。
- **自助服務與 API 驅動**：租戶可透過 UI 或 API 自行佈建 vApp/VM/網路。
- **內容交付**：透過 Catalog 管理與散佈 vApp Template、ISO 等內容。

---

## 3. 資源層級架構 (Resource Hierarchy)

VCD 以階層方式組織資源，由 Provider 端逐層向下切分至租戶可消費的單位。

### 3.1 層級結構

```
System (Provider)
   └── Provider VDC (PVDC)      ── 對應 vCenter resource pool + 儲存 + NSX
          └── Organization (租戶)
                 └── Org VDC    ── 資源切片，套用配額
                        └── vApp / VM / Network / Edge Gateway
```

### 3.2 各層級說明

| 層級 | 角色 | 對應底層資源 | 說明 |
| --- | --- | --- | --- |
| **System (Provider)** | 平台最上層管理範圍 | 整體 VMware 基礎架構 | Provider 管理員操作的全域範圍 |
| **Provider VDC (PVDC)** | Provider 端資源池 | vCenter resource pool + 儲存 + NSX | 將實體運算、儲存、網路資源納入 VCD 管理 |
| **Organization (Org)** | 租戶 | — | 一個獨立的租戶單位，含使用者、角色、政策 |
| **Org VDC** | 租戶資源切片 | 由 PVDC 切分而來 | 套用配額 (quota) 與配置模型，租戶實際消費資源之處 |
| **vApp / VM** | 工作負載 | VM / 應用群組 | 租戶部署的虛擬機與應用 |
| **Network / Edge Gateway** | 租戶網路 | NSX-T 網路服務 | 租戶網路與邊界閘道服務 |

> PVDC 對應 vCenter resource pool、儲存與 NSX；Org VDC 為自 PVDC 切分出的資源切片並套用配額。具體支援的 vCenter / NSX 版本相容性以官方文件為準。

---

## 4. Org VDC 配置模型 (Allocation Models)

Org VDC 決定資源如何自 PVDC 配置給租戶。VCD 提供下列配置模型：

| 配置模型 | 說明 | 適用情境 |
| --- | --- | --- |
| **Allocation Pool** | 配置一個資源池，可設定保證 (guaranteed) 百分比 | 需可預期容量但保留彈性的租戶 |
| **Pay-As-You-Go** | 依實際使用量計算，無預先保留 | 用量浮動、按使用計費 |
| **Reservation Pool** | 完全保留 (reserved) 資源給租戶 | 需要穩定且專屬效能的關鍵負載 |
| **Flex** | 彈性配置模型 | 需要在單一模型下混合不同配置策略 |

> 各模型的保證百分比、超賣 (overcommit) 行為與計費細節，請以官方文件為準。

---

## 5. 網路與 Edge Gateway

### 5.1 Edge Gateway

在 VCD 中，**Edge Gateway 由 NSX-T 提供**，作為租戶網路的邊界閘道，提供下列服務：

| 服務 | 說明 |
| --- | --- |
| **NAT** | 網路位址轉換 |
| **FW (Firewall)** | 防火牆規則 |
| **LB (Load Balancer)** | 負載平衡 |
| **VPN** | 虛擬私有網路連線 |

> Edge Gateway 的規模 (form factor)、各服務的詳細功能與上限，請以官方文件為準。

---

## 6. Catalog 內容管理

**Catalog** 為 vApp Template、Template 與 ISO 的內容庫，是 VCD 中內容散佈與標準化交付的核心機制。

| 內容類型 | 用途 |
| --- | --- |
| **vApp Template** | 預先打包的 vApp/VM 範本，供快速部署 |
| **Template** | VM 範本 |
| **ISO** | 安裝媒體 / 映像檔 |

Catalog 可供租戶內部使用，亦可在多個租戶或多個 instance 間共享。跨區域 / 跨 instance 的進階情境，請見 [第 13 章 Global Distributed Catalogs](#13-global-distributed-catalogs)。

---

## 7. 10.6 / 10.6.1 新功能總覽

下表彙整 VCD 10.6 / 10.6.1 的重點新功能。各功能的詳細說明見後續章節。

| 功能 | 摘要 | 對應章節 |
| --- | --- | --- |
| **Multi-Tier Tenancy (三層租戶)** | Provider → Sub-Provider → Managed Org 的分層委派模型 | [§8](#8-multi-tier-tenancy-三層租戶) |
| **Kubernetes 細粒度授權** | 控制 tenant user 對 cluster 或個別 namespace 的存取 | [§9](#9-kubernetes-整合與細粒度授權) |
| **VM 放置與合規** | 依 guest OS 定義 VM Group 並放置至指定 host/cluster | [§10](#10-vm-放置與合規-vm-placement--compliance) |
| **IP Retention (IP 保留期)** | 在 sub-provider/managed org 層級自訂 IP 保留期 | [§11](#11-ip-管理ip-spacesip-retention-與-data-center-group) |
| **強制 API Token 過期** | 即時撤銷 / 失效 API Token | [§12](#12-安全api-token-強制過期與存取控制) |
| **Global Distributed Catalogs** | 跨區域 / instance 維護內容 | [§13](#13-global-distributed-catalogs) |
| **IP Spaces 集中化 IP 管理** | 集中化的 IP 位址管理 | [§11](#11-ip-管理ip-spacesip-retention-與-data-center-group) |
| **Data Center Group** | 跨 Org VDC 共用 NSX-T 網路與 DFW | [§11](#11-ip-管理ip-spacesip-retention-與-data-center-group) |
| **CSE (Container Service Extension)** | K8s 自助佈建 | [§9](#9-kubernetes-整合與細粒度授權) |

> 上述功能跨 10.6 與 10.6.1 兩個版本。各功能首次導入或增強所屬的確切版本 (10.6 或 10.6.1)，請以官方 Release Notes 為準。

---

## 8. Multi-Tier Tenancy 三層租戶

VCD 10.6 / 10.6.1 導入 **Multi-Tier Tenancy (三層租戶)**，將傳統的兩層 (Provider → Org) 模型擴充為三層：

```
Provider
   └── Sub-Provider
          └── Managed Org
```

### 8.1 角色與委派

| 層級 | 角色定位 | 典型對象 |
| --- | --- | --- |
| **Provider** | 平台擁有者，最高管理權 | VCSP / 企業中央 IT |
| **Sub-Provider** | 受委派的中間層，可管理其下的 Managed Org | MSP / 事業群 / 區域團隊 |
| **Managed Org** | 最終租戶 | 終端客戶 / 部門 |

### 8.2 適用情境

- **MSP (Managed Service Provider)**：VCSP 將一部分管理權委派給 MSP，由 MSP 再服務其終端客戶。
- **企業分層委派**：企業中央 IT 將管理權下放給事業群或區域團隊，再由其管理下屬組織。

> Multi-Tier Tenancy 適合需要**分層委派**的 MSP 與大型企業情境。各層可委派的具體權限範圍與限制，請以官方文件為準。

---

## 9. Kubernetes 整合與細粒度授權

### 9.1 CSE (Container Service Extension)

**CSE (Container Service Extension)** 為 VCD 提供 **Kubernetes 叢集的自助佈建 (self-service provisioning)** 能力，讓租戶可在 VCD 內自行建立與管理 K8s 叢集。

### 9.2 Kubernetes 細粒度授權

10.6 / 10.6.1 強化 Kubernetes 授權的粒度：

- 可控制 **tenant user 對 cluster 或個別 namespace 的存取**。
- 支援**多使用者共用同一叢集**，各自於專屬 **namespace** 部署工作負載。

| 授權層級 | 控制範圍 | 效果 |
| --- | --- | --- |
| **Cluster 層級** | 整個 K8s 叢集 | 使用者可存取整個叢集 |
| **Namespace 層級** | 個別 namespace | 使用者僅能存取被授權的 namespace |

此能力讓「多租戶 / 多使用者共用叢集」成為可行的營運模式，在降低叢集數量的同時維持隔離。

> CSE 版本相容性、支援的 Kubernetes 版本與 runtime，請以官方文件為準。

---

## 10. VM 放置與合規 (VM Placement & Compliance)

VCD 10.6 / 10.6.1 提供以 **guest OS** 為依據的 **VM 放置 (placement) 與合規 (compliance)** 控制：

- 依 **guest OS** 定義 **VM Group**。
- 將特定 VM Group 放置 (placement) 至**指定的 host 或 cluster**。

### 10.1 典型應用

| 需求 | 作法 |
| --- | --- |
| 授權合規 (例如特定 OS 須綁定特定實體主機) | 將該 guest OS 的 VM Group 綁定至特定 host/cluster |
| 效能 / 隔離需求 | 將特定工作負載放置至專屬 cluster |
| 法規 / 資料落地 | 將 VM 限制於符合規範的硬體範圍內 |

> VM Group 與 host/cluster 對應的設定方式及限制，請以官方文件為準。

---

## 11. IP 管理：IP Spaces、IP Retention 與 Data Center Group

### 11.1 IP Spaces 集中化 IP 管理

**IP Spaces** 提供**集中化的 IP 位址管理**，讓 Provider 能以一致方式管理與配發 IP 位址資源，取代分散管理的方式。

### 11.2 IP Retention (IP 保留期)

**IP Retention** 允許在 **sub-provider / managed org 層級**自訂 **IP 保留期**，適用於下列 IP 配發方式：

| IP 配發方式 | 說明 |
| --- | --- |
| **Static Pool** | 自靜態位址池自動配發 |
| **Static Manual** | 手動指定的靜態位址 |
| **DHCP** | 透過 DHCP 動態取得 |

關鍵行為：**當 VM 被刪除或 NIC 被移除時，IP 仍會在設定的保留期內被保留**，避免位址立即釋放造成的重複配發或追蹤困難。

### 11.3 Data Center Group

**Data Center Group** 讓多個 **Org VDC** 之間能**共用 NSX-T 網路與 DFW (Distributed Firewall)**：

- 跨 Org VDC 共用網路與分散式防火牆政策。
- 適用於需要跨資源切片統一網路與安全政策的情境。

> IP 保留期的最大值、IP Spaces 與 Data Center Group 的詳細上限與相依條件，請以官方文件為準。

---

## 12. 安全：API Token 強制過期與存取控制

### 12.1 強制 API Token 過期

VCD 10.6 / 10.6.1 提供**強制 API Token 過期 (forced expiry)** 能力：

- 可**即時撤銷 (revoke) 或失效 (invalidate)** API Token。
- 提升 token 生命週期管理與安全治理能力，降低長期有效 token 的外洩風險。

### 12.2 安全治理建議 (Checklist)

- [ ] 為 API Token 設定合理的過期 / 撤銷政策。
- [ ] 對外洩或離職人員相關 token 立即執行撤銷。
- [ ] 定期稽核有效 token 清單。
- [ ] 結合租戶角色與權限 (RBAC) 控制 token 可操作範圍。

> 強制 API Token 過期的具體設定路徑與政策選項，請以官方文件為準。

---

## 13. Global Distributed Catalogs

**Global Distributed Catalogs** 讓內容 (Catalog) 能**跨區域 (region) 或跨 instance 維護**：

- 在多區域 / 多 VCD instance 環境下，統一維護與散佈 vApp Template、ISO 等內容。
- 降低各區域各自維護內容造成的版本不一致問題。

### 13.1 適用情境

| 情境 | 價值 |
| --- | --- |
| 多區域 VCSP | 一次發佈，全區域可用 |
| 多 instance 企業環境 | 內容版本一致性 |
| 災難復原 / 多站點 | 內容於多站點間維持可用 |

> Global Distributed Catalogs 的同步機制、頻率與相依元件，請以官方文件為準。

---

## 14. 部署與營運 Checklist

### 14.1 規劃階段

- [ ] 確認 VCD 10.6 / 10.6.1 與底層 vCenter、NSX-T 的版本相容性 (以官方文件為準)。
- [ ] 規劃 PVDC 對應的 vCenter resource pool、儲存與 NSX 資源。
- [ ] 設計 Organization 與 Org VDC 切分策略與配額。
- [ ] 選定各租戶適用的配置模型 (Allocation Pool / Pay-As-You-Go / Reservation Pool / Flex)。
- [ ] 評估是否採用 Multi-Tier Tenancy (Provider → Sub-Provider → Managed Org)。

### 14.2 網路與安全

- [ ] 規劃 Edge Gateway (NSX-T) 之 NAT / FW / LB / VPN 需求。
- [ ] 評估採用 IP Spaces 集中化 IP 管理。
- [ ] 設定 IP Retention 保留期 (Static Pool / Static Manual / DHCP)。
- [ ] 評估以 Data Center Group 跨 Org VDC 共用 NSX-T 網路與 DFW。
- [ ] 制定 API Token 過期 / 撤銷政策。

### 14.3 內容與工作負載

- [ ] 建立 Catalog (vApp Template / Template / ISO)。
- [ ] 評估採用 Global Distributed Catalogs 跨區域 / instance 維護內容。
- [ ] 規劃 VM Group 與 host/cluster 之 VM 放置與合規政策。

### 14.4 Kubernetes

- [ ] 評估部署 CSE (Container Service Extension) 提供 K8s 自助佈建。
- [ ] 設計 Kubernetes 細粒度授權 (cluster / namespace 層級)。
- [ ] 規劃多使用者共用叢集的 namespace 隔離策略。

---

## 15. 常見使用情境 (Use Cases)

| 情境 | 建議採用的 VCD 能力 |
| --- | --- |
| VCSP 對外提供多租戶 IaaS | 完整資源層級 + 配置模型 + Edge Gateway + Catalog |
| MSP 分層轉售 | Multi-Tier Tenancy (Provider → Sub-Provider → Managed Org) |
| 企業內部分層委派 | Multi-Tier Tenancy + RBAC |
| 多租戶 / 多使用者共用 K8s | CSE + Kubernetes namespace 細粒度授權 |
| 授權合規 / 資料落地 | VM 放置與合規 (VM Group → host/cluster) |
| 集中化 IP 治理 | IP Spaces + IP Retention |
| 跨 Org VDC 統一網路與安全 | Data Center Group (共用 NSX-T 網路 + DFW) |
| 多區域內容一致性 | Global Distributed Catalogs |
| API 安全治理 | 強制 API Token 過期 / 撤銷 |

---

## 16. 名詞對照表 (Glossary)

| 縮寫 / 名詞 | 全名 / 說明 |
| --- | --- |
| **VCD** | VMware Cloud Director |
| **VCSP** | VMware Cloud Service Provider |
| **MSP** | Managed Service Provider |
| **IaaS** | Infrastructure as a Service |
| **PVDC** | Provider VDC (Provider Virtual Data Center) |
| **Org VDC** | Organization Virtual Data Center |
| **vApp** | 虛擬應用 (一組 VM 與其關係的封裝) |
| **Edge Gateway** | 租戶網路邊界閘道 (由 NSX-T 提供) |
| **NAT / FW / LB / VPN** | Network Address Translation / Firewall / Load Balancer / Virtual Private Network |
| **DFW** | Distributed Firewall |
| **Catalog** | vApp Template / Template / ISO 內容庫 |
| **CSE** | Container Service Extension |
| **DHCP** | Dynamic Host Configuration Protocol |
| **RBAC** | Role-Based Access Control |

---

## 17. 參考來源

- VMware Cloud Director 10.6 Release Notes — Broadcom TechDocs
  https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-106-release-notes.html
- VMware Cloud Director 10.6.1 Is Here — What's New (VMware Cloud Provider Blog, 2025-02)
  https://blogs.vmware.com/cloudprovider/2025/02/vmware-cloud-director-10-6-1-is-here-whats-new.html
- VMware Cloud Director 10.6 Documentation — Broadcom TechDocs
  https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6.html
