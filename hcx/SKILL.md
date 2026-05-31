---
name: hcx
description: |
  VMware HCX 應用遷移與工作負載移動平台專門知識。涵蓋 Service Mesh、Interconnect (IX)、Network Extension (NE / L2 延伸)、Mobility Optimized Networking (MON) 與其 Route Policy、五種遷移類型 (HCX vMotion、Cold、Bulk Migration、RAV / Replication Assisted vMotion、OSAM / OS-Assisted Migration with Sentinel)、RAV/Bulk 並行擴充規模 (300/600/1000)、HCX Advanced vs Enterprise 授權與 VCF Solution Licensing 自動繼承、最新版本 4.11.x 與 EOS/升級路徑，以及與 VCF / VMC on AWS / GCVE / AVS 的遷移整合。當使用者詢問 HCX、跨站遷移、資料中心搬遷、機房整併、上雲遷移、大規模 VM 搬遷、零停機 / 低停機遷移、L2 網路延伸、RAV、MON、Sentinel / OSAM、KVM / Hyper-V 遷移、HCX 授權、HCX 版本升級、HCX 設計規劃 / runbook / 簡報時觸發。注意 WAN Optimization 已於 4.11.4 移除，請勿列為現行功能。
---

# VMware HCX

HCX 是 VMware by Broadcom 的「應用遷移與工作負載移動平台」，用來在資料中心之間、
或上雲（VCF / VMC on AWS / GCVE / AVS）做大規模、低停機的 VM 遷移與 L2 網路延伸。
HCX 現已納入 VCF 體系（透過 VCF Operations 提供 Workload Mobility 能力）。
本 skill 用來回答 HCX 的元件、遷移類型選型、網路延伸 / MON 規劃、授權與版本升級。

> 重要：**WAN Optimization 已於 HCX 4.11.3 棄用、4.11.4 移除**，升級前必須先移除此服務。
> 請勿再把 WAN Optimization 當成現行功能介紹。

## 使用時機

- 規劃資料中心搬遷 / 機房整併 / 上雲遷移
- 選擇正確的遷移類型（HCX vMotion / Cold / Bulk / RAV / OSAM）
- L2 網路延伸 (Network Extension) 與 MON / MON Route Policy 規劃
- 跨站零停機 / 低停機大規模搬遷與並行度（300 / 600 / 1000）規劃
- HCX 與 VCF / GCVE / AVS / VMC 整合
- HCX 授權版本選擇（Advanced vs Enterprise）與 VCF Solution Licensing 自動繼承
- HCX 版本升級路徑、EOS（支援終止）查詢
- 撰寫遷移計畫 / runbook / 簡報

## 核心重點

### HCX 核心元件

| 元件 | 角色 |
|------|------|
| HCX Manager | 來源端 (Connector) 與目的端 (Cloud Manager) 的管理平面 |
| **Interconnect (IX / HCX-IX)** | 建立站對站加密傳輸通道，承載遷移流量（單一 IX 最高約 1.6 Gbps、單流約 1 Gbps）|
| **Network Extension (NE / HCX-NE)** | L2 延伸，讓 VM 跨站保留同網段 IP / MAC，免 re-IP；MON 為其進階能力 |
| **Sentinel** | OS-Assisted Migration (OSAM) 代理，遷移非 vSphere 來源（KVM / Hyper-V）|
| **Service Mesh** | 依指定的 Compute / Network Profile，把上述服務組合部署成 appliance |

> 註：WAN Optimization 為已移除元件，不再列入現行元件清單。

### 遷移類型選型（重點）

| 類型 | 停機 | 機制 | 適用 |
|------|------|------|------|
| **HCX vMotion** | 開機零停機 | 跨站 live vMotion | 單台 / 少量、需即時搬移 |
| **Cold Migration** | 關機 | 直接搬已關機的 VM | 已關機 / 可關機的 VM |
| **Bulk Migration** | 切換時短停（重啟切換）| vSphere Replication，平行多台、無 agent | 大批量、可排程 |
| **RAV (Replication Assisted vMotion)** | 大規模零停機 | Replication（並行複製）+ vMotion（序列切換）| 大批量 + 低停機 |
| **OSAM (OS-Assisted Migration)** | 視情況 | Sentinel agent | 非 vSphere 來源（KVM / Hyper-V）|

選型口訣：
- **量大又要零停機** → **RAV**
- **量大、可接受切換短停、可排程** → **Bulk**
- 少量、立即、零停機 → **HCX vMotion**
- VM 已關機 → **Cold**
- 來源不是 vSphere → **OSAM（Sentinel）**

並行規模（RAV / Bulk，HCX 4.10+，見 KB 373010）：每個 HCX Manager 預設 **300** 並行，
可依規模調至 **Medium 600 / Large 1000**。詳見 `references/hcx-migration.md`。

### Network Extension 與 MON

- **Network Extension (NE)**：跨站延伸 L2 segment，VM 搬到對端仍保留 IP / MAC，避免 re-IP。
- **Mobility Optimized Networking (MON)**：NE 的進階能力，解決 tromboning（流量繞回來源閘道）。
  - 在 SDDC 端的 T1 以 **/32** 啟用閘道，加入靜態路由但**不向 on-prem 通告**。
  - **MON Route Policy** 決定出向：符合策略 → 送回來源；未符合 → 走 T0。
  - **Bulk 遷移的 VM 在 SDDC 端自動啟用 MON**；**vMotion / RAV / pre-extended 預設仍用 on-prem 閘道**。

### 授權

- **HCX Advanced**：基本遷移與 NE。
- **HCX Enterprise**：含 **RAV、MON、OSAM** 等進階能力。
- **VCF 5.1.1+ 搭配 HCX 4.9.0+**：由 **VCF Solution Licensing 於系統層級優先自動繼承 Enterprise（含 RAV / MON）**，毋須另管金鑰、毋須另購。

## 版本與新功能

| 版本 | 狀態 / 重點 |
|------|------|
| **4.11.4** | 最新主線（GA 日期 / build 以官方 release notes 為準，頁面更新 2026-04-23）；**移除 WAN Optimization**；修約 16 項問題（RAV Secure Boot、反向遷移驗證、multicast、switchover 排程器）|
| **4.11.3** | 2025-09-29 釋出（Connector 24972695 / Cloud 24972693）；**棄用 WAN Optimization**；支援延長至 **2027-10-11** |
| 4.11.0 起 | 僅 local mode、無 System Updates 通知；Bulk 關機等待 100 → 300 秒 |
| **4.11.2 及更早** | 已 **EOS（2025-12-24）** |

升級路徑：
- 4.9.x / 4.10.x / 4.11.x → 可直升 **4.11.4**
- 4.4 – 4.8.3 → 先升 **4.9.2**，再升 4.11.4
- 4.2.4 – 4.3.3 → 經 **4.8.3** → 4.9.2 → 4.11.4

> 升級到 4.11.4 前，務必先移除 WAN Optimization 服務。

## 與其他 skill 關係

- 上雲 / 混合雲拓撲與簡報（GCVE / AVS / VMC on AWS、內雲外雲公雲）→ 搭配 `vcf-hybrid-cloud`。
- VCF 9.1 升級 / 平台規劃 → 搭配 `vcf-91-ppt`、`vcf-financial` 等情境 skill。
- 本 skill 聚焦 HCX 元件、遷移選型、網路延伸、授權與版本；簡報產製交由對應 VCF 簡報 skill。

## 重要提醒

- **WAN Optimization 已移除**（4.11.3 棄用 / 4.11.4 移除），勿列為現行功能，升級前須先移除。
- **VCF 5.1.1+ / HCX 4.9.0+ 自動繼承 Enterprise**（含 RAV / MON），毋須另購金鑰。
- **HCX 4.11.2 及更早已 EOS（2025-12-24）**，規劃前確認版本是否仍受支援。
- **4.11.0 起僅 local mode、無自動更新通知**，升級需手動規劃。
- RAV / Bulk 並行度與規模受 IX / NE appliance 數量與頻寬限制（單 IX ~1.6 Gbps、單流 ~1 Gbps）；大規模請依 KB 373010 規劃並調整至 600 / 1000。
- 規劃前確認 HCX 版本與來源 / 目的端 vSphere、NSX 相容性。

## 權威來源

- HCX 4.11.4 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/vmware-hcx-4114-release-notes.html
- HCX 4.11.3 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/vmware-hcx-4113-release-notes.html
- About HCX Licensing (4.11): https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/about-hcx-licensing.html
- Migrating VMs with HCX (4.11): https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11/migrating-virtual-machines-with-vmware-hcx.html
- About HCX MON: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/about-hcx-mobility-optimized-networking.html
- RAV / Bulk scalability (KB 373010): https://knowledge.broadcom.com/external/article/373010
- KB 321604: https://knowledge.broadcom.com/external/article/321604
- HCX Licensing & Packaging Overview: https://www.vmware.com/docs/vmw-hcx-licensing-and-packaging-solution-overview
- VMware HCX 產品頁: https://www.vmware.com/products/cloud-infrastructure/hcx
