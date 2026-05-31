# VMware HCX 遷移技術參考

## 1. 部署拓撲 (Service Mesh)

```
[來源站]                          [目的站 / 雲]
HCX Connector  ── IX tunnel ──>   HCX Cloud Manager
   │  NE / WANopt / Sentinel        │  NE / WANopt
   └── Service Mesh (依 Compute/Network Profile 部署 appliance) ──┘
```

部署順序：
1. 兩端安裝 HCX Manager（來源 Connector、目的 Cloud）。
2. Site Pairing（站對站配對）。
3. 建立 Network Profile / Compute Profile。
4. 建立 **Service Mesh**（會自動部署 IX / NE / WANopt / Sentinel appliance）。
5. 開始遷移 / 網路延伸。

## 2. 遷移類型詳解

### 2.1 Bulk Migration
- 使用 **vSphere Replication** 協定，平行排程搬移多台 VM，**無需 agent**。
- 來源 VM 持續運作，複製完成後在「切換窗」一次性重啟切換到目的端。
- 適合：大批量、可排程、可接受一次短重啟。

### 2.2 HCX vMotion
- 跨站 live vMotion，近乎零停機。
- 適合：單台或少量、需即時搬移。

### 2.3 Replication Assisted vMotion (RAV)
- 結合 **vSphere Replication + vMotion**：
  - 提交大批 VM，指定切換窗。
  - VM 持續複製，只在切換窗套用 delta。
  - 多台同時複製，切換窗時對每台做一次 delta vMotion cycle。
- 等於「Bulk 的規模 + vMotion 的近零停機」。
- 適合：大規模 + 低停機要求。

### 2.4 Cold Migration
- 已關機的 VM 直接搬移。

### 2.5 OS-Assisted Migration (OSAM / Sentinel)
- 透過 **Sentinel** agent 遷移非 vSphere 來源（KVM、Hyper-V）。

## 3. Network Extension (NE) 與 MON

### 3.1 NE
- 跨站延伸 L2 segment，VM 搬遷後保留同網段 IP / MAC，免 re-IP。
- 是大規模遷移「先搬機器、網段慢慢收斂」的關鍵。

### 3.2 Mobility Optimized Networking (MON)
- NE 的進階功能，解決 **tromboning**：VM 已在對端，但流量繞回來源 gateway。
- MON 讓對端 VM 的東西/南北向走 cloud gateway，降低延遲。
- 行為差異（重要）：
  - **Bulk 遷移的 VM** → 在 SDDC 端**自動啟用 MON**。
  - **vMotion / RAV 遷移的 VM** → 預設走 **on-prem gateway**，需在 HCX UI/API 手動切到 cloud gateway。
- 可在三個層級開關 MON：延伸網段時 / 已延伸網段 / 個別 VM。

## 4. 規模與效能 (RAV / Bulk Scalability)

- 並行遷移數量受 **IX / NE appliance 數量**與 **WAN 頻寬**限制。
- 大規模專案應依官方 RAV/Bulk scalability guide 計算所需 Service Mesh appliance 數量。
- WAN Optimization 提供去重 / 壓縮，改善高延遲 / 低頻寬鏈路效能。

## 5. 上雲遷移整合

HCX 是上雲遷移的標準工具，支援：
- **VMC on AWS**
- **Google Cloud VMware Engine (GCVE)**
- **Azure VMware Solution (AVS)**
- **VCF / VVF 私有雲跨站**

典型流程：建立 site pairing → NE 延伸關鍵網段 → RAV/Bulk 分批遷移 →
逐步把 gateway 切到雲端 (MON) → 收尾下線來源。

## 6. 遷移規劃 Checklist

- [ ] 盤點 VM 數量、大小、變更率，估算複製時間
- [ ] 選定遷移類型（Bulk / RAV / vMotion / OSAM）
- [ ] 規劃需延伸的 L2 segment 與 MON 策略
- [ ] 依規模計算 IX / NE appliance 數量與頻寬
- [ ] 確認 HCX 版本與來源/目的 vSphere、NSX 相容性
- [ ] 規劃切換窗 (cutover window) 與回退方案
- [ ] 確認授權版本是否含 RAV / MON / OSAM (Enterprise)

## 來源
- https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/vmware-hcx-user-guide-4-8/extending-networks-with-vmware-hcx/hcx-network-extension-with-mobility-optimized-networking/about-hcx-mobility-optimized-networking.html
- https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/vmware-hcx-user-guide-4-8/migrating-virtual-machines-with-vmware-hcx/understanding-vmware-hcx-replication-assisted-vmotion.html
- https://knowledge.broadcom.com/external/article/373010
- https://www.vmware.com/docs/vmw-hcx-application-migration-and-mobility-platform
