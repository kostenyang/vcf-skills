# VMware HCX 完整指南

> 版本基準：HCX 4.11.x（最新主線 4.11.4，頁面更新 2026-04-23）。
> 本文所有內容均依 Broadcom 官方文件與 KB。重要變更：**WAN Optimization 已移除**、
> **HCX 已納入 VCF 體系**、**VCF 5.1.1+ 自動繼承 Enterprise 授權**。

## 目錄

1. [HCX 是什麼](#1-hcx-是什麼)
2. [核心元件與架構](#2-核心元件與架構)
3. [部署流程 (Service Mesh)](#3-部署流程-service-mesh)
4. [遷移類型與選型](#4-遷移類型與選型)
5. [RAV / Bulk 並行規模與效能](#5-rav--bulk-並行規模與效能)
6. [Network Extension 與 MON](#6-network-extension-與-mon)
7. [授權版本與 VCF 繼承](#7-授權版本與-vcf-繼承)
8. [版本、支援與升級路徑](#8-版本支援與升級路徑)
9. [4.11.x 新功能與變更](#9-411x-新功能與變更)
10. [上雲遷移整合](#10-上雲遷移整合)
11. [遷移規劃 Checklist](#11-遷移規劃-checklist)
12. [FAQ](#12-faq)
13. [參考來源](#13-參考來源)

---

## 1. HCX 是什麼

VMware HCX 是 VMware by Broadcom 的「應用遷移與工作負載移動平台 (Application Migration and Mobility Platform)」，
用於在資料中心之間、或從地端上雲（VCF / VMC on AWS / GCVE / AVS）進行**大規模、低停機**的
VM 遷移與 **L2 網路延伸**。

HCX 目前已納入 **VCF 體系**，透過 **VCF Operations 的 Workload Mobility** 能力提供。
其核心價值在於：免 re-IP（保留 IP / MAC）、多種遷移類型可選、可批次大規模並行搬遷、
並能在搬遷期間維持來源與目的端的網路互通。

---

## 2. 核心元件與架構

| 元件 | 角色 |
|------|------|
| **HCX Manager** | 來源端 (Connector) 與目的端 (Cloud Manager) 的管理平面 |
| **Interconnect (IX / HCX-IX)** | 站對站加密傳輸通道，承載遷移流量（單 IX ~1.6 Gbps、單流 ~1 Gbps）|
| **Network Extension (NE / HCX-NE)** | L2 延伸，VM 跨站保留同網段 IP / MAC，免 re-IP；MON 為其進階功能 |
| **Sentinel** | OS-Assisted Migration (OSAM) 代理，遷移非 vSphere 來源（KVM / Hyper-V）|
| **Service Mesh** | 依指定的 Compute / Network Profile，把上述服務組合部署成 appliance |

> **WAN Optimization 已移除**（4.11.3 棄用、4.11.4 移除），不再屬於現行元件。

架構示意：

```
[來源站]                          [目的站 / 雲]
HCX Connector  ── IX tunnel ──>   HCX Cloud Manager
   │  NE / Sentinel                  │  NE
   └── Service Mesh (依 Compute/Network Profile 部署 appliance) ──┘
```

---

## 3. 部署流程 (Service Mesh)

1. 兩端安裝 **HCX Manager**（來源 Connector、目的 Cloud）。
2. **Site Pairing**（站對站配對）。
3. 建立 **Network Profile / Compute Profile**。
4. 建立 **Service Mesh**（自動部署 IX / NE / Sentinel appliance）。
5. 開始遷移 / 網路延伸。

> 既有環境升級到 4.11.4 前，必須先移除 WAN Optimization 服務。

---

## 4. 遷移類型與選型

| 類型 | 停機 | 機制 | 適用情境 |
|------|------|------|----------|
| **HCX vMotion** | 開機零停機 | 跨站 live vMotion | 單台 / 少量、需即時搬移 |
| **Cold Migration** | 關機 | 直接搬已關機的 VM | 已關機 / 可關機 VM |
| **Bulk Migration** | 切換時短停（重啟）| vSphere Replication，平行多台、無 agent | 大批量、可排程 |
| **RAV (Replication Assisted vMotion)** | 大規模零停機 | Replication（並行複製）+ vMotion（序列切換）| 大批量 + 低停機 |
| **OSAM (OS-Assisted Migration)** | 視情況 | Sentinel agent | 非 vSphere 來源（KVM / Hyper-V）|

選型口訣：
- **量大 + 零停機** → **RAV**
- **量大 + 可接受切換短停 + 可排程** → **Bulk**
- 少量、立即、零停機 → **HCX vMotion**
- VM 已關機 → **Cold**
- 來源非 vSphere → **OSAM（Sentinel）**

RAV 細節：複製階段為**並行**，切換階段為**序列**（switchover 序列），
每台 VM 做一次 delta vMotion，達成「Bulk 的規模 + vMotion 的零停機」。

---

## 5. RAV / Bulk 並行規模與效能

依 **KB 373010**（HCX 4.10+）：

| 設定檔 | 每個 HCX Manager 並行遷移數 |
|--------|------|
| 預設 (Default) | **300** |
| Medium | **600** |
| Large | **1000** |

頻寬：
- 單一 **IX** appliance 最高約 **1.6 Gbps**。
- **單一資料流 (single flow)** 約 **1 Gbps**。

規劃要點：並行遷移數受 IX / NE appliance 數量與 WAN 頻寬限制；大規模專案依 KB 373010
計算 Service Mesh appliance 數並調整至 600 / 1000。WAN Optimization 已移除，
遠距 / 高延遲鏈路改以增加 appliance、提升頻寬與規劃切換窗因應。

---

## 6. Network Extension 與 MON

### 6.1 Network Extension (NE)

跨站延伸 L2 segment，VM 搬遷後保留同網段 IP / MAC，免 re-IP，是「先搬機器、網段慢慢收斂」的關鍵。

### 6.2 Mobility Optimized Networking (MON)

MON 為 NE 的功能，解決 **tromboning**（VM 已在對端，但流量繞回來源閘道）。

運作機制：
- 在 SDDC 端的 **T1** 以 **/32** 為遷移後 VM 啟用閘道，加入靜態路由但**不向 on-prem 通告**。
- **MON Route Policy** 決定出向流量：
  - **符合**策略 → 送回來源 (on-prem)。
  - **未符合**策略 → 走 T0（本地 / 雲端出口）。

各遷移類型的 MON 預設行為：

| 遷移類型 | MON 預設 |
|----------|----------|
| **Bulk** | SDDC 端**自動啟用 MON** |
| **vMotion** | 預設用 **on-prem 閘道**（需手動切換）|
| **RAV** | 預設用 **on-prem 閘道**（需手動切換）|
| **pre-extended（事先延伸網段）** | 預設用 **on-prem 閘道** |

---

## 7. 授權版本與 VCF 繼承

| 版本 | 內容 |
|------|------|
| **HCX Advanced** | 基本遷移與 Network Extension |
| **HCX Enterprise** | 含 **RAV、MON、OSAM** 等進階能力 |

VCF 自動繼承：
- **VCF 5.1.1+ 搭配 HCX 4.9.0+** 時，由 **VCF Solution Licensing 於系統層級優先自動繼承 Enterprise**（含 RAV / MON），
  **毋須另管金鑰、毋須另購**。
- HCX 現屬 VCF 體系（VCF Operations Workload Mobility）。

---

## 8. 版本、支援與升級路徑

| 版本 | 狀態 / 重點 |
|------|------|
| **4.11.4** | 最新主線（GA 日期 / build 以官方 release notes 為準，頁面更新 2026-04-23）；移除 WAN Optimization；修約 16 問題 |
| **4.11.3** | 2025-09-29 釋出（Connector **24972695** / Cloud **24972693**）；棄用 WAN Optimization；支援延長至 **2027-10-11** |
| 4.11.0 起 | 僅 **local mode**、無 **System Updates** 通知；Bulk 關機等待 100 → **300 秒** |
| **4.11.2 及更早** | 已 **EOS（2025-12-24）** |

升級路徑：

| 來源版本 | 升級路線 |
|----------|----------|
| 4.9.x / 4.10.x / 4.11.x | **直升 4.11.4** |
| 4.4 – 4.8.3 | 先升 **4.9.2** → 4.11.4 |
| 4.2.4 – 4.3.3 | 經 **4.8.3** → 4.9.2 → 4.11.4 |

升級注意：升級到 4.11.4 前**必須先移除 WAN Optimization**；4.11.0 起無自動更新通知，需手動規劃。

---

## 9. 4.11.x 新功能與變更

- **WAN Optimization**：4.11.3 棄用、**4.11.4 移除**（升級前須移除）。
- **4.11.0 起**：僅 local mode、無 System Updates 通知。
- **Bulk 關機等待**：100 秒 → **300 秒**。
- **支援延長**：4.11.3+ 延至 **2027-10-11**。
- **4.11.4 修復**約 16 項問題，含 **RAV Secure Boot**、**反向遷移驗證**、**multicast**、**switchover 排程器**。
- **RAV / Bulk 可擴充**：並行 300 → 600 / 1000。

---

## 10. 上雲遷移整合

HCX 支援：
- **VMC on AWS**
- **Google Cloud VMware Engine (GCVE)**
- **Azure VMware Solution (AVS)**
- **VCF / VVF 私有雲跨站**

典型流程：site pairing → NE 延伸關鍵網段 → RAV / Bulk 分批遷移 →
逐步把 gateway 切到雲端 (MON) → 收尾下線來源。

---

## 11. 遷移規劃 Checklist

- [ ] 盤點 VM 數量、大小、變更率，估算複製時間
- [ ] 選定遷移類型（HCX vMotion / Cold / Bulk / RAV / OSAM）
- [ ] 規劃需延伸的 L2 segment 與 MON / MON Route Policy 策略
- [ ] 依規模計算 IX / NE appliance 數量與頻寬（單 IX ~1.6 Gbps、單流 ~1 Gbps；並行 300 / 600 / 1000）
- [ ] 確認 HCX 版本與來源 / 目的 vSphere、NSX 相容性
- [ ] 確認 HCX 版本未 EOS（4.11.2 及更早已於 2025-12-24 EOS）
- [ ] 升級前**移除 WAN Optimization**（4.11.4 已移除）
- [ ] 確認授權：VCF 5.1.1+ / HCX 4.9.0+ 是否已自動繼承 Enterprise（含 RAV / MON）
- [ ] 規劃切換窗 (cutover window) 與回退方案

---

## 12. FAQ

**Q1：要零停機又要大量搬遷，該用哪種？**
A：**RAV**。複製階段並行、切換階段序列，達成大規模零停機。

**Q2：WAN Optimization 還能用嗎？**
A：不行。4.11.3 棄用、**4.11.4 已移除**。升級到 4.11.4 前須先移除此服務。遠距鏈路改以增加 appliance、提升頻寬與規劃切換窗因應。

**Q3：RAV / MON 要不要另外買授權？**
A：屬 **Enterprise**。但 **VCF 5.1.1+ 搭配 HCX 4.9.0+** 時，由 **VCF Solution Licensing 自動繼承 Enterprise（含 RAV / MON）**，毋須另購、毋須另管金鑰。

**Q4：我的 HCX 版本還受支援嗎？**
A：**4.11.2 及更早已於 2025-12-24 EOS**；4.11.3+ 支援延至 **2027-10-11**。建議升級至 4.11.4。

**Q5：為什麼 vMotion / RAV 搬過去的 VM 流量還是繞回地端？**
A：因為 vMotion / RAV / pre-extended 的 VM **預設仍用 on-prem 閘道**，需在 HCX 手動切到 cloud gateway（啟用 MON）。Bulk 則會自動啟用 MON。

**Q6：非 vSphere 的 KVM / Hyper-V 能搬嗎？**
A：可以，使用 **OSAM（OS-Assisted Migration）**，透過 **Sentinel** agent 遷移。

**Q7：一個 IX 能跑多快？並行上限多少？**
A：單 IX 約 **1.6 Gbps**、單流約 **1 Gbps**；每個 HCX Manager 預設並行 **300**，可調至 **600 / 1000**（KB 373010）。

**Q8：HCX 從很舊的版本怎麼升到 4.11.4？**
A：4.9.x / 4.10.x / 4.11.x 可直升；4.4–4.8.3 先升 4.9.2；4.2.4–4.3.3 經 4.8.3 再升 4.9.2，最後到 4.11.4。

---

## 13. 參考來源

- HCX 4.11.4 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/vmware-hcx-4114-release-notes.html
- HCX 4.11.3 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/vmware-hcx-4113-release-notes.html
- About HCX Licensing (4.11): https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/about-hcx-licensing.html
- Migrating VMs with HCX (4.11): https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/migrating-virtual-machines-with-vmware-hcx.html
- About HCX MON (4.8): https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/about-hcx-mobility-optimized-networking.html
- RAV / Bulk scalability (KB 373010): https://knowledge.broadcom.com/external/article/373010
- KB 321604: https://knowledge.broadcom.com/external/article/321604
- HCX Licensing & Packaging Solution Overview: https://www.vmware.com/docs/vmw-hcx-licensing-and-packaging-solution-overview
- VMware HCX 產品頁: https://www.vmware.com/products/cloud-infrastructure/hcx
