---
name: hcx
description: >-
  VMware HCX 專門知識 skill。涵蓋工作負載遷移與混合雲移動：Service Mesh、
  Interconnect (IX)、Network Extension (NE/L2)、WAN Optimization、
  遷移類型 (Bulk Migration、HCX vMotion、RAV / Replication Assisted vMotion、Cold)、
  Mobility Optimized Networking (MON)、Sentinel (OS-Assisted Migration / OSAM)、
  HCX Advanced vs Enterprise、與 VCF / VMC on AWS / GCVE / AVS 的遷移整合。
  當使用者詢問 HCX、跨站遷移、上雲遷移、大規模 VM 搬遷、L2 延伸、
  零停機 / 低停機遷移、RAV、MON、HCX 設計或簡報時觸發。
---

# VMware HCX

HCX 是 VMware/Broadcom 的「應用遷移與工作負載移動平台」，用來在資料中心之間、
或上雲（VCF / VMC on AWS / GCVE / AVS）做大規模、低停機的 VM 遷移與 L2 網路延伸。
本 skill 用來回答 HCX 的元件、遷移類型選型、網路延伸與設計規劃。

## 使用時機

- 規劃資料中心搬遷 / 機房整併 / 上雲遷移
- 選擇正確的遷移類型（Bulk / vMotion / RAV / Cold / OSAM）
- L2 網路延伸 (Network Extension) 與 MON 規劃
- 跨站零停機 / 低停機大規模搬遷
- HCX 與 VCF / GCVE / AVS / VMC 整合
- HCX 授權版本選擇（Advanced vs Enterprise）
- 撰寫遷移計畫 / runbook / 簡報

## HCX 核心元件

| 元件 | 角色 |
|------|------|
| HCX Manager | 來源端 (Connector) 與目的端 (Cloud Manager) 的管理平面 |
| **Interconnect (IX / HCX-IX)** | 建立站對站加密傳輸通道，承載遷移流量 |
| **Network Extension (NE / HCX-NE)** | L2 延伸，讓 VM 跨站保留同網段與 IP |
| **WAN Optimization (WANopt)** | 去重 / 壓縮 / 加速，改善遠距遷移效能 |
| **Sentinel** | OS-Assisted Migration (OSAM) 代理，遷移非 vSphere (KVM/Hyper-V) 來源 |
| **Service Mesh** | 把上述服務組合部署在指定的 Compute/Network Profile 之間 |

## 遷移類型選型 (重點)

| 類型 | 停機 | 適用 | 機制 |
|------|------|------|------|
| **Cold Migration** | 關機 | 已關機的 VM | 直接搬 |
| **HCX vMotion** | 近乎零 | 單台 / 少量、即時 | live vMotion 跨站 |
| **Bulk Migration** | 一次重啟 (切換窗) | 大批量、可排程 | vSphere Replication，平行多台、無 agent |
| **RAV (Replication Assisted vMotion)** | 近乎零 | 大批量 + 低停機 | Replication + vMotion 結合，持續複製 delta，切換窗時做 delta vMotion |
| **OSAM (OS-Assisted)** | 視情況 | 非 vSphere 來源 (KVM/Hyper-V) | Sentinel agent |

選型口訣：
- 要**零停機又要量大** → **RAV**。
- 要**量大、可接受一次切換重啟、可排程** → **Bulk**。
- 少量、立即、零停機 → **HCX vMotion**。
- 來源不是 vSphere → **OSAM (Sentinel)**。

## 網路延伸與 MON

- **Network Extension (NE)**：跨站延伸 L2 segment，VM 搬到對端仍保留 IP / MAC，
  避免 re-IP。
- **Mobility Optimized Networking (MON)**：NE 的進階能力，優化已延伸 segment 上
  VM 的流量路由，降低 *tromboning*（流量繞回來源閘道）造成的延遲。
  - **Bulk 遷移的 VM 在 SDDC 端會自動啟用 MON**。
  - **vMotion / RAV 遷移的 VM** 預設仍走 on-prem gateway，需在 HCX UI/API
    手動指定改走 cloud gateway。
  - MON 可在「延伸網段時」「已延伸網段」「個別 VM」三個層級啟用 / 停用。

詳細內容見 `references/hcx-migration.md`。

## 授權版本

- **HCX Advanced**：基本遷移與 NE（常隨 VCF / VVF 提供）。
- **HCX Enterprise**：進階能力，如 RAV、MON、OSAM、SRM 整合、跨雲移動等。
  （實際授權內容以 Broadcom 當前授權方案為準。）

## 重要提醒

- RAV / Bulk 的並行度與規模受 IX/NE appliance 數量與頻寬限制，
  大規模遷移請參考官方 RAV scalability guide 規劃 appliance 數量。
- 規劃前務必確認 HCX 版本與來源/目的端 vSphere、NSX 的相容性。

## 權威來源
- HCX User Guide (Broadcom TechDocs): https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx.html
- About MON: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/vmware-hcx-user-guide-4-8/extending-networks-with-vmware-hcx/hcx-network-extension-with-mobility-optimized-networking/about-hcx-mobility-optimized-networking.html
- Understanding RAV: https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/vmware-hcx-user-guide-4-8/migrating-virtual-machines-with-vmware-hcx/understanding-vmware-hcx-replication-assisted-vmotion.html
- RAV/Bulk scalability guide (4.10+): https://knowledge.broadcom.com/external/article/373010
