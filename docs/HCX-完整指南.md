# VMware HCX 完整技術指南 (遷移與混合雲移動)

> 文件版本：v1.0
> 適用對象：VMware/Broadcom 架構師、雲端遷移工程師、平台維運團隊
> 撰寫基準：本文內容以下方「參考來源」之 Broadcom 官方技術文件為依據。文中未明確列出的版本號、效能上限、規模數字等，一律以官方文件為準。

---

## 目錄

1. [HCX 概觀](#1-hcx-概觀)
2. [核心元件](#2-核心元件)
3. [部署架構與部署順序](#3-部署架構與部署順序)
4. [遷移類型詳解](#4-遷移類型詳解)
5. [Network Extension 與 Mobility Optimized Networking (MON)](#5-network-extension-與-mobility-optimized-networking-mon)
6. [規模與效能考量](#6-規模與效能考量)
7. [授權版本](#7-授權版本-hcx-advanced-vs-enterprise)
8. [上雲與混合雲整合場景](#8-上雲與混合雲整合場景)
9. [遷移方式選型決策](#9-遷移方式選型決策)
10. [部署與遷移 Checklist](#10-部署與遷移-checklist)
11. [常見議題與設計建議](#11-常見議題與設計建議)
12. [參考來源](#12-參考來源)

---

## 1. HCX 概觀

VMware HCX 是一個**應用遷移與工作負載移動 (application migration and workload mobility) 平台**，設計目標是在**跨站 (site-to-site) 與上雲 (on-prem to cloud)** 的情境下，進行**大規模、低停機 (low-downtime)** 的工作負載遷移，並提供 **L2 網路延伸 (Layer 2 Network Extension)** 能力。

HCX 的核心價值在於：

- 將既有工作負載從來源環境搬遷到目的環境，過程中盡可能降低停機時間。
- 透過 L2 延伸，讓 VM 在遷移前後可**保留原有的 IP 位址與網段**，避免重新規劃網路。
- 支援多種遷移方式，依工作負載特性 (數量、停機容忍度、來源平台) 彈性選擇。
- 整合多種公有雲與私有雲目的端，作為混合雲 (hybrid cloud) 移動的統一平台。

---

## 2. 核心元件

HCX 由多個元件組成，部分為常駐管理元件，部分為由 Service Mesh 自動部署的服務 appliance。

| 元件 | 角色 | 說明 |
|------|------|------|
| **HCX Manager** | 管理平面 | 來源端為 **Connector**，目的端為 **Cloud Manager**。負責配置、配對、Service Mesh 管理與遷移作業協調。 |
| **Interconnect (IX)** | 加密傳輸通道 | 提供來源與目的之間的加密傳輸通道，承載遷移流量。 |
| **Network Extension (NE)** | L2 延伸 | 將來源端網段以 Layer 2 方式延伸到目的端，使 VM 可保留原 IP/網段。 |
| **WAN Optimization** | 傳輸最佳化 | 提供**去重 (de-duplication) 與壓縮 (compression)**，提升 WAN 傳輸效率。 |
| **Sentinel** | OSAM 代理 | OS-Assisted Migration 所使用的代理，用於遷移 **KVM / Hyper-V** 等非 vSphere 來源。 |
| **Service Mesh** | 服務組合與部署 | 將上述服務 (IX、NE、WAN Optimization 等) 組合並**自動部署**到對應站點。 |

### 2.1 元件關係

- **HCX Manager** 是配置與作業的入口；其餘服務 appliance 並非手動逐一安裝，而是透過 **Service Mesh** 自動部署。
- **IX** 承載遷移資料流；**NE** 承載延伸網段的 L2 流量；**WAN Optimization** 針對傳輸內容做去重與壓縮。
- **Sentinel** 僅在使用 **OSAM** 遷移非 vSphere 來源時才需要。

---

## 3. 部署架構與部署順序

HCX 的標準部署流程為線性步驟，後一步驟依賴前一步驟完成：

1. **兩端安裝 HCX Manager**
   - 來源端部署 **Connector**，目的端部署 **Cloud Manager**。
2. **Site Pairing (站點配對)**
   - 建立來源 HCX Manager 與目的 HCX Manager 之間的信任與連線關係。
3. **建立 Network Profile 與 Compute Profile**
   - 定義服務 appliance 將使用的網路 (管理、上行、vMotion、延伸等) 與運算資源。
4. **建立 Service Mesh**
   - 依據 Compute/Network Profile，**自動部署** IX、NE、WAN Optimization 等服務 appliance。
5. **執行遷移 / 網路延伸**
   - 在 Service Mesh 就緒後，開始進行 VM 遷移與 L2 網段延伸。

> 部署順序摘要：
> **兩端裝 HCX Manager → Site Pairing → 建 Network/Compute Profile → 建 Service Mesh (自動部署 appliance) → 遷移 / 延伸**

---

## 4. 遷移類型詳解

HCX 支援多種遷移方式，分別對應不同的工作負載規模、停機容忍度與來源平台。

### 4.1 Cold Migration

- **機制**：將 VM **關機 (power off)** 後直接搬遷。
- **適用**：可接受關機的工作負載。
- **特性**：流程最單純，但遷移期間 VM 不可用。

### 4.2 HCX vMotion

- **機制**：跨站的 **live vMotion**。
- **停機**：**近乎零停機 (near-zero downtime)**。
- **適用**：**少量、需要即時遷移**的工作負載。
- **特性**：適合一次處理少量 VM 的即時搬遷。

### 4.3 Bulk Migration

- **機制**：使用 **vSphere Replication**，**平行 (parallel)** 遷移多台 VM。
- **Agent**：**無需 agent**。
- **切換窗 (cutover)**：在切換時**一次重啟 (reboot)**。
- **適用**：**大批量、可排程**的遷移作業。
- **特性**：適合需要在排程切換窗內完成大量 VM 遷移的場景。

### 4.4 RAV (Replication Assisted vMotion)

- **機制**：**Replication 與 vMotion 結合**。先透過 replication **持續複製 delta**，於切換窗時以 **delta vMotion** 完成最終切換。
- **適用**：**大規模 + 低停機**並重的場景。
- **特性**：兼顧 Bulk 的平行/規模能力與 vMotion 的低停機特性。

### 4.5 OSAM (OS-Assisted Migration)

- **機制**：透過 **Sentinel** 代理，遷移**非 vSphere 來源**。
- **適用來源**：**KVM / Hyper-V** 等非 vSphere 平台。
- **特性**：以 OS 層級協助方式進行遷移。

### 4.6 遷移類型比較表

| 遷移類型 | 底層機制 | 停機程度 | 規模 / 平行度 | Agent | 切換方式 | 典型適用 |
|----------|----------|----------|----------------|-------|----------|----------|
| **Cold Migration** | 關機直接搬 | VM 關機期間不可用 | — | — | — | 可接受關機的 VM |
| **HCX vMotion** | 跨站 live vMotion | 近乎零停機 | 少量 | — | live | 少量即時遷移 |
| **Bulk Migration** | vSphere Replication | 切換時一次重啟 | 平行多台 (大批量) | 無 agent | 切換窗一次重啟 | 大批量、可排程 |
| **RAV** | Replication + vMotion | 低停機 | 大規模 | — | 切換窗做 delta vMotion | 大規模且低停機 |
| **OSAM** | Sentinel 代理 | 以官方文件為準 | 以官方文件為準 | Sentinel 代理 | 以官方文件為準 | 非 vSphere 來源 (KVM/Hyper-V) |

> 註：表中未明確列出的細項 (如 OSAM 的停機與切換細節) 以官方文件為準。

---

## 5. Network Extension 與 Mobility Optimized Networking (MON)

### 5.1 Network Extension (NE)

NE 提供 **L2 延伸**，讓來源網段延伸至目的端，使遷移後的 VM 能**保留原有 IP 與網段**。

### 5.2 為何需要 MON：Tromboning 問題

在 L2 延伸的環境中，若遷移到目的端 (如 SDDC) 的 VM 其預設閘道 (default gateway) 仍位於**來源端 (on-prem)**，則 VM 對外或跨網段流量會**繞回來源 gateway** 再出去，形成 **tromboning (流量繞回來源 gateway)**，造成路徑迂迴與延遲。

**MON (Mobility Optimized Networking)** 是 **NE 的進階能力**，用以解決 tromboning。

### 5.3 MON 的預設行為 (依遷移方式不同)

| 遷移方式 | MON / Gateway 預設行為 |
|----------|------------------------|
| **Bulk Migration** | 遷移後的 VM 在 **SDDC 端自動啟用 MON**。 |
| **vMotion / RAV** | 遷移後的 VM **預設走 on-prem gateway**；需在 **HCX UI / API 手動切換**到 cloud gateway。 |

> 重點：vMotion 與 RAV 遷移的 VM 不會自動使用 cloud gateway，必須由管理者手動切換，否則會持續經由 on-prem gateway (可能形成 tromboning)。

### 5.4 MON 的三層級開關

MON 可在以下三個層級進行開關控制：

1. **延伸網段時** — 在執行網段延伸的當下設定。
2. **已延伸網段** — 對既有已延伸的網段進行調整。
3. **個別 VM** — 針對單一 VM 層級控制。

---

## 6. 規模與效能考量

HCX 的遷移規模主要受以下因素限制：

- **IX / NE appliance 數量** — 服務 appliance 的數量影響可承載的並行遷移與延伸能力。
- **WAN 頻寬** — 跨站傳輸頻寬直接影響遷移吞吐與完成時間。

> 進行**大規模遷移規劃**時，請參考官方的 **RAV / Bulk scalability guide** 取得實際的並行數、吞吐與規模上限數字。本文不臆測具體上限，相關數字一律**以官方文件為準**。

設計建議 (基於上述限制因素)：

- 大規模專案應評估是否需要**部署多個 Service Mesh / 多組 appliance** 以提升並行度。
- WAN Optimization 的去重與壓縮有助於在受限頻寬下提升有效傳輸效率。
- 切換窗 (cutover) 的安排需配合 Bulk / RAV 的特性與排程能力。

---

## 7. 授權版本 (HCX Advanced vs Enterprise)

| 授權版本 | 涵蓋能力 | 取得方式 (參考) |
|----------|----------|------------------|
| **HCX Advanced** | 基本遷移能力 + **Network Extension (NE)** | 常隨 **VCF / VVF** 提供 |
| **HCX Enterprise** | 進階能力，包含 **RAV、MON、OSAM** 等 | 進階授權 |

> 選型重點：
> - 若僅需基本遷移 + L2 延伸 → **HCX Advanced** 可能已足夠。
> - 若需要 **RAV (大規模低停機)**、**MON (解決 tromboning)** 或 **OSAM (遷移非 vSphere 來源)** → 需 **HCX Enterprise**。
> - 各版本確切功能對照以官方文件為準。

---

## 8. 上雲與混合雲整合場景

HCX 可作為混合雲移動的統一平台，目的端整合包含：

- **VMC on AWS** (VMware Cloud on AWS)
- **GCVE** (Google Cloud VMware Engine)
- **AVS** (Azure VMware Solution)
- **VCF 私有雲跨站** (on-prem VCF 之間或私有雲跨站遷移)

這些目的端皆可作為 HCX 的 Cloud 側，配合 Site Pairing 與 Service Mesh 進行遷移與 L2 延伸。

---

## 9. 遷移方式選型決策

以下為基於本文已查證事實的選型指引：

| 需求情境 | 建議遷移方式 |
|----------|--------------|
| 可接受 VM 關機 | **Cold Migration** |
| 少量 VM、需即時且近乎零停機 | **HCX vMotion** |
| 大批量 VM、可安排排程切換窗、可接受切換時一次重啟 | **Bulk Migration** |
| 大規模 VM 且要求低停機 | **RAV** |
| 來源為非 vSphere (KVM / Hyper-V) | **OSAM (需 Sentinel)** |

**Gateway / MON 決策補充：**

- 使用 **Bulk** 遷移到 SDDC → MON 自動啟用 (預設處理 tromboning)。
- 使用 **vMotion / RAV** → 記得在 **HCX UI / API 手動將 gateway 切到 cloud gateway**，避免流量繞回 on-prem。

---

## 10. 部署與遷移 Checklist

### 10.1 部署前 (Pre-deployment)

- [ ] 確認授權版本 (Advanced / Enterprise) 是否涵蓋所需功能 (RAV / MON / OSAM)。
- [ ] 確認目的端類型 (VMC on AWS / GCVE / AVS / VCF 私有雲)。
- [ ] 規劃 WAN 頻寬，評估是否符合遷移規模需求。
- [ ] 若為大規模，查閱官方 **RAV / Bulk scalability guide** 確認規模上限。
- [ ] 規劃 Network Profile / Compute Profile 所需網段與運算資源。

### 10.2 部署 (Deployment)

- [ ] 來源端安裝 HCX **Connector**。
- [ ] 目的端安裝 HCX **Cloud Manager**。
- [ ] 完成 **Site Pairing**。
- [ ] 建立 **Network Profile** 與 **Compute Profile**。
- [ ] 建立 **Service Mesh**，確認 IX / NE / WAN Optimization 等 appliance 自動部署完成。
- [ ] (若遷移非 vSphere 來源) 確認 **Sentinel** 已就緒以支援 **OSAM**。

### 10.3 網路延伸 (Network Extension)

- [ ] 確認需延伸的網段清單。
- [ ] 執行 **Network Extension** 延伸 L2 網段。
- [ ] 評估是否需啟用 **MON** 以避免 tromboning。
- [ ] 決定 MON 控制層級 (延伸網段時 / 已延伸網段 / 個別 VM)。

### 10.4 遷移執行 (Migration)

- [ ] 依工作負載特性選定遷移方式 (Cold / vMotion / Bulk / RAV / OSAM)。
- [ ] Bulk / RAV：規劃切換窗 (cutover) 時間。
- [ ] **Bulk → SDDC**：確認 MON 自動啟用情形。
- [ ] **vMotion / RAV**：於 **HCX UI / API 手動將 gateway 切換至 cloud gateway**。
- [ ] 驗證遷移後 VM 連線、IP 保留與對外路徑是否正確 (無非預期 tromboning)。

---

## 11. 常見議題與設計建議

- **流量繞回 (tromboning)**：在 L2 延伸環境中，若 gateway 仍在 on-prem，跨網段流量會繞回來源端。對 vMotion / RAV 遷移的 VM，務必手動切換至 cloud gateway。
- **遷移方式混用**：同一專案可依不同工作負載特性混用多種遷移方式 (例如多數用 Bulk / RAV，少量即時用 vMotion)。
- **規模瓶頸**：規模主要受 IX / NE appliance 數量與 WAN 頻寬限制，大規模需參考官方 scalability guide。
- **非 vSphere 來源**：KVM / Hyper-V 來源需透過 Sentinel 進行 OSAM，並需具備對應授權。
- **不確定項目**：本文未涵蓋或未明確的版本、數字、上限，請一律以 Broadcom 官方文件為準。

---

## 12. 參考來源

- VMware HCX 官方技術文件 (總入口)：
  https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx.html
- About HCX Mobility Optimized Networking (MON)：
  https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/vmware-hcx-user-guide-4-8/extending-networks-with-vmware-hcx/hcx-network-extension-with-mobility-optimized-networking/about-hcx-mobility-optimized-networking.html
- Understanding VMware HCX Replication Assisted vMotion (RAV)：
  https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/vmware-hcx-user-guide-4-8/migrating-virtual-machines-with-vmware-hcx/understanding-vmware-hcx-replication-assisted-vmotion.html
- Broadcom Knowledge Base 文章 (Article 373010)：
  https://knowledge.broadcom.com/external/article/373010
