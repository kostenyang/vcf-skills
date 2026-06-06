# VMware HCX 遷移技術參考

> 適用版本基準：HCX 4.11.x（最新主線 4.11.4）。WAN Optimization 已於 4.11.3 棄用、
> 4.11.4 移除，本文不再列為現行元件 / 功能。HCX 現屬 VCF 體系（VCF Operations Workload Mobility）。

## 1. 部署拓撲 (Service Mesh)

```
[來源站]                          [目的站 / 雲]
HCX Connector  ── IX tunnel ──>   HCX Cloud Manager
   │  NE / Sentinel                  │  NE
   └── Service Mesh (依 Compute/Network Profile 部署 appliance) ──┘
```

部署順序：
1. 兩端安裝 HCX Manager（來源 Connector、目的 Cloud）。
2. Site Pairing（站對站配對）。
3. 建立 Network Profile / Compute Profile。
4. 建立 **Service Mesh**（自動部署 IX / NE / Sentinel appliance）。
5. 開始遷移 / 網路延伸。

> 註：WAN Optimization 為已移除服務，新部署不含此 appliance；既有環境升級至 4.11.4 前必須移除。

## 2. 遷移類型詳解

### 2.1 HCX vMotion
- 跨站 live vMotion，**開機零停機**。
- 適合：單台或少量、需即時搬移。
- MON 行為：遷移後**預設仍用 on-prem 閘道**（需手動切換）。

### 2.2 Cold Migration
- 已關機的 VM 直接搬移（關機狀態）。

### 2.3 Bulk Migration
- 使用 **vSphere Replication** 協定，**平行**排程搬移多台 VM，**無需 agent**。
- 來源 VM 持續運作，複製完成後在「切換窗」做短停（重啟）切換到目的端。
- 4.11.0 起 Bulk 關機等待由 100 秒調整為 **300 秒**。
- MON 行為：Bulk 遷移的 VM 在 SDDC 端**自動啟用 MON**。
- 適合：大批量、可排程、可接受切換短停。

### 2.4 Replication Assisted vMotion (RAV)
- 結合 **vSphere Replication + vMotion**：
  - 複製階段**並行**進行多台 VM。
  - 切換階段為**序列**（switchover 序列），每台做一次 delta vMotion，達到大規模零停機。
- 等於「Bulk 的規模 + vMotion 的零停機」。
- 適合：大規模 + 低停機要求。
- MON 行為：遷移後**預設仍用 on-prem 閘道**（需手動切換）。

### 2.5 OS-Assisted Migration (OSAM / Sentinel)
- 透過 **Sentinel** agent 遷移非 vSphere 來源（**KVM、Hyper-V**）。

## 3. RAV / Bulk 並行規模與效能 (KB 373010，HCX 4.10+)

| 設定檔 | 每個 HCX Manager 並行遷移數 |
|--------|------|
| 預設 (Default) | **300** |
| Medium | **600** |
| Large | **1000** |

頻寬上限：
- 單一 **IX** appliance 最高約 **1.6 Gbps**。
- **單一資料流 (single flow)** 約 **1 Gbps**。

規劃要點：
- 並行遷移數量受 **IX / NE appliance 數量**與 **WAN 頻寬**限制。
- 大規模專案應依 KB 373010 計算所需 Service Mesh appliance 數量，並視需要調整至 600 / 1000。
- WAN Optimization 已移除，遠距 / 高延遲鏈路改以增加 appliance、提升頻寬與規劃切換窗因應。

## 4. Network Extension (NE) 與 MON

### 4.1 NE
- 跨站延伸 L2 segment，VM 搬遷後保留同網段 IP / MAC，免 re-IP。
- 是大規模遷移「先搬機器、網段慢慢收斂」的關鍵。

### 4.2 Mobility Optimized Networking (MON)
MON 為 Network Extension 的功能，解決 **tromboning**（VM 已在對端，但流量繞回來源閘道）。

運作機制：
- 在 SDDC 端的 **T1** 以 **/32** 為遷移後的 VM 啟用閘道，並加入**靜態路由**，但**不向 on-prem 通告**。
- **MON Route Policy** 決定出向流量路徑：
  - **符合**策略 → 流量**送回來源 (on-prem)**。
  - **未符合**策略 → 流量**走 T0**（本地 / 雲端出口）。

各遷移類型的 MON 預設行為（重要）：

| 遷移類型 | MON 預設 |
|----------|----------|
| **Bulk** | 在 SDDC 端**自動啟用 MON** |
| **vMotion** | 預設用 **on-prem 閘道**（需手動切換）|
| **RAV** | 預設用 **on-prem 閘道**（需手動切換）|
| **pre-extended（事先延伸網段）** | 預設用 **on-prem 閘道** |

## 5. 授權版本與 VCF 繼承

- **HCX Advanced**：基本遷移與 NE。
- **HCX Enterprise**：含 **RAV、MON、OSAM** 等進階能力。
- **VCF 5.1.1+ 搭配 HCX 4.9.0+**：由 **VCF Solution Licensing 於系統層級優先自動繼承 Enterprise**（含 RAV / MON），**毋須另管金鑰、毋須另購**。
- HCX 現屬 VCF 體系（VCF Operations Workload Mobility）。

## 6. 版本、支援與升級路徑

| 版本 | 狀態 / 重點 |
|------|------|
| **4.11.4** | 最新主線（GA 日期 / build 以官方 release notes 為準，頁面更新 2026-04-23）；**移除 WAN Optimization**；修約 16 問題（RAV Secure Boot、反向遷移驗證、multicast、switchover 排程器）|
| **4.11.3** | 2025-09-29 釋出（Connector **24972695** / Cloud **24972693**）；**棄用 WAN Optimization**；支援延長至 **2027-10-11** |
| 4.11.0 起 | 僅 **local mode**、無 **System Updates** 通知；Bulk 關機等待 100 → **300 秒** |
| **4.11.2 及更早** | 已 **EOS（2025-12-24）** |

升級路徑：
- **4.9.x / 4.10.x / 4.11.x → 可直升 4.11.4**
- **4.4 – 4.8.3 → 先升 4.9.2**，再升 4.11.4
- **4.2.4 – 4.3.3 → 經 4.8.3** → 4.9.2 → 4.11.4

升級注意：
- 升級到 4.11.4 前**必須先移除 WAN Optimization**。
- 4.11.0 起無自動更新通知，需手動規劃升級。

## 7. 上雲遷移整合

HCX 是上雲遷移的標準工具，支援：
- **VMC on AWS**
- **Google Cloud VMware Engine (GCVE)**
- **Azure VMware Solution (AVS)**
- **VCF / VVF 私有雲跨站**

典型流程：建立 site pairing → NE 延伸關鍵網段 → RAV / Bulk 分批遷移 →
逐步把 gateway 切到雲端 (MON) → 收尾下線來源。

## 8. 遷移規劃 Checklist

- [ ] 盤點 VM 數量、大小、變更率，估算複製時間
- [ ] 選定遷移類型（HCX vMotion / Cold / Bulk / RAV / OSAM）
- [ ] 規劃需延伸的 L2 segment 與 MON / MON Route Policy 策略
- [ ] 依規模計算 IX / NE appliance 數量與頻寬（單 IX ~1.6 Gbps、單流 ~1 Gbps；並行 300 / 600 / 1000）
- [ ] 確認 HCX 版本與來源 / 目的 vSphere、NSX 相容性
- [ ] 確認 HCX 版本未 EOS（4.11.2 及更早已於 2025-12-24 EOS）
- [ ] 升級前**移除 WAN Optimization**（4.11.4 已移除）
- [ ] 確認授權：VCF 5.1.1+ / HCX 4.9.0+ 是否已自動繼承 Enterprise（含 RAV / MON）
- [ ] 規劃切換窗 (cutover window) 與回退方案

## 來源
- HCX 4.11.4 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/vmware-hcx-4114-release-notes.html
- HCX 4.11.3 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/vmware-hcx-4113-release-notes.html
- About HCX Licensing (4.11): https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/about-hcx-licensing.html
- Migrating VMs with HCX (4.11): https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/migrating-virtual-machines-with-vmware-hcx.html
- About HCX MON: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/about-hcx-mobility-optimized-networking.html
- RAV / Bulk scalability (KB 373010): https://knowledge.broadcom.com/external/article/373010
- KB 321604: https://knowledge.broadcom.com/external/article/321604
- HCX Licensing & Packaging Overview: https://www.vmware.com/docs/vmw-hcx-licensing-and-packaging-solution-overview
- VMware HCX 產品頁: https://www.vmware.com/products/cloud-infrastructure/hcx
