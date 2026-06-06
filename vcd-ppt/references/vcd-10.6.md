# VMware Cloud Director 10.6 系列技術參考 (10.6 / 10.6.1 / 10.6.1.2)

> 版本、build 與功能歸屬一律以 Broadcom 官方 Release Notes 為準。不確定者標註「以官方文件為準」。

## 0. 版本譜系與 Build 號

VCD 10.6 系列**目前最新版為修補版 10.6.1.2**，並非 10.6.1。

| 版本 | GA / 釋出日期 | Build (installed build) | 性質 |
|------|------|------|------|
| 10.6 | 27 JUN 2024 | 24055916 (24055813) | GA |
| 10.6.0.1 | 修補版 | — | 維護性修補 |
| 10.6.1 | 31 JAN 2025 | 24532678 (24532667) | 新功能釋出，as part of the VCF offering |
| 10.6.1.1 | 修補版 | — | 維護性修補 |
| **10.6.1.2** | **05 DEC 2025** | **25088252 (25086345)** | **目前最新**，維護性釋出 |

- 10.6.1.2 為維護性釋出：bug fixes、更新 appliance base OS 與開源元件，文件列出約 **50+** 個已解決問題，無新功能特性。
- **日期警示**：部分第三方追蹤站 (virten.net vTracker、搜尋摘要) 對 10.6.1.2 出現「2024-12-05」與 build 號互換的錯誤標示。官方 TechDocs Release Notes 標示為 **05 DEC 2025**，以官方為準。
- **10.6.2**：本研究於官方 TechDocs 未找到 10.6.2 的獨立 Release Notes 或 GA 資訊，最高僅到 10.6.1.2 修補線。若聲稱已有 10.6.2 GA 屬未經證實，以官方文件為準。

## 1. 產品定位與交付模式

- VCD 是 Broadcom (前 VMware) 的多租戶雲服務交付平台，主供 **VCSP / 電信業 / 企業私有雲**對外提供多租戶 IaaS。
- **交付模式更新**：VCD 現納入 **VMware Cloud Foundation (VCF)** 方案授權交付，10.6.1 即「as part of the VCF offering」釋出，不再是獨立 VMware 產品線。

## 2. 租戶模型 (Tenancy)

### 2.1 三層租戶 (Three-Tier / Multi-Tier Tenancy) — 10.6 GA 導入

```
Provider (System)
└── Sub-Provider        ← 受限管理權限，管理一組受限的租戶
    └── Managed Org / Tenant  ← 最終租戶 (客戶)
```

- 雲供應商可建立 sub-provider 組織，對一組受限的租戶具有受限管理權限 (provider → sub-provider → tenant 三層)。
- 適合 MSP (多層轉售) 或大型企業內部分層 (例如：總部 → 子公司 → BU)。
- 每層可有獨立的角色、配額與委派管理。

### 2.2 資源抽象

- **Provider VDC (PVDC)**：底層 vCenter resource pool + datastore + NSX 的抽象。
- **Organization VDC (OrgVDC)** 配置模型：
  - *Allocation Pool*：配置一定比例保證資源。
  - *Pay-As-You-Go*：用多少算多少，無前置保留。
  - *Reservation Pool*：完整保留，租戶自行超分。
  - *Flex*：彈性混合模型 (10.x 主推)。

## 3. 10.6 GA 主要技術事實 (27 JUN 2024，Build 24055916)

- **三層租戶 (Three-Tier Tenancy)**：見 §2.1。
- **資料庫需求提升**：外部資料庫組態需 **PostgreSQL 13 或更新版本**。
- **Global / Distributed Catalogs (全域 / 分散式目錄)**：可建立並發佈跨多個 vCenter 執行個體、跨多個 VCD 站點皆一致的目錄 (透過共享儲存 / 複寫技術)。
- **IPv6 支援**：VCD appliance cells 可運行於 IPv6 網路環境。
- **每 VM 多重快照 (Multiple VM Snapshots)**：支援每台 VM 多個快照，上限由供應商設定。
- **容器管理**：Kubernetes 叢集管理員可控管租戶使用者對叢集 / namespace 的存取，並可檢視容器應用的修訂歷史。
- **規模上限提升**：VM 達 **55,000**、並發遠端主控台達 **22,000**、最大使用者數 **300,000**、群組內 Organization VDC 達 **2,000**。
- **Appliance OS**：改基於 **Photon OS 4.0** (安全性提升、OS 套件升級)。
- **安全**：本版解決 **CVE-2024-22272**。

## 4. 10.6.1 主要技術事實 (31 JAN 2025，Build 24532678) — 最新一輪新功能

| 功能 | 說明 |
|------|------|
| **Guest OS-Aware VM Placement** | 管理員可為特定 OS 類型定義 VM Groups，將 VM 放置於特定主機 / 叢集以符合合規與授權 (例如 Microsoft 授權需求)，跨所有租戶套用 |
| **API Token 安全控管** | 管理員可強制 API token 到期 (force expiration)，並可即時失效 (instantly invalidate) 以因應安全或管理變更 |
| **Custom IP Retention (自訂 IP 保留期)** | 可在 sub-provider 與受管組織層級設定自訂 IP 保留期間，即使 VM 刪除或 NIC 移除仍可保留 IP |
| **Gateway Firewall 強制狀態可視性** | 對 T1 與 T0 防火牆的 enforcement status 有完整可視性，並具管理員覆寫能力 |
| **Stateful Firewall 存取控管** | 供應商可限制租戶在未取得 ANS (Advanced Network Security / 安全堆疊) 授權時新增防火牆規則 |
| **可分享的自訂 Segment Profile** | 供應商可將自訂網路 segment profile 範本散佈 / 複製給租戶組織或跨多個 NSX projects，以標準化組態 |
| **IPv6 Transparent Load Balancing** | 恢復對 VMware Avi Load Balancer 的 IPv6 支援，pool members 可看到 client 的來源 IP |

其他修正：更新 Custom Task API、修復 Virtual Data Centers 檢視問題、移除舊版 NSX MP API 參照。

## 5. 10.6.1.2 技術事實 (05 DEC 2025，Build 25088252)

維護性釋出 — bug fixes + 更新 appliance base OS 與開源元件，約 50+ 已解決問題。代表性修復：

- VM 頁面快照儲存值顯示錯誤。
- flex allocation model 相關的 VM 開機失敗。
- 組織 IP spaces 配額修改問題。
- SAML 以 NameID 對應 email 的問題。
- RabbitMQ 事件處理失敗。
- vSAN datastore 上儲存原則 relocation 錯誤。
- guest customization 設定失敗。
- 資料庫升級 constraint violation。
- NSX edge gateway 在第 129+ 位置編輯 IPsec VPN tunnel 的問題。

## 6. 網路 (NSX 整合)

- **Edge Gateway**：租戶南北向，提供 NAT / FW / LB / IPSec & L2 VPN。
- **Org VDC Network**：Routed / Isolated / Imported。
- **Data Center Group**：跨多個 OrgVDC 共用 NSX 網路與分散式防火牆 (DFW)。
- **Gateway Firewall**：T0 / T1 enforcement status 可視性與管理員覆寫 (10.6.1)。
- **Avi Load Balancer**：IPv6 Transparent LB，pool members 可見 client 來源 IP (10.6.1)。

## 7. IP Spaces 與多層租戶

- **IP Spaces** 是 VCD 的 IP 配置 / 追蹤系統，由一組**不重疊**的 IP ranges 與小型 CIDR blocks 構成；一個 IP space **只能是 IPv4 或 IPv6，不可混用**。
- **Private IP Space**：專屬單一租戶 (建立時指定的組織)，對該組織 IP 消耗不受限。
- **Shared / 共享 IP 池**：供應商可建立共享 IP 位址池供租戶在配額內 draw down (配額可全域設定並可對個別租戶覆寫)。
- **對齊三層模型**：IP Spaces / IPsec VPN 管理對齊 tenant、sub-provider、provider 三種角色，皆可管理 IP 生命週期與設定 VPN，並可用 **BGP** 控制哪些 IP prefix 走 VPN；供應商以 IP Spaces 管理公私網位址時可自動化租戶的 BGP 設定。
- IP Spaces 概念最早於 **VCD 10.4.1** 引入，本研究確認其在 10.6 已對齊三層權限模型。

## 8. Kubernetes / 容器

- **Container Service Extension (CSE)**：在 VCD 上提供 Tanzu / TKG 叢集自助佈建。
- **K8s 細粒度授權** (10.6 起)：控制 tenant 使用者對叢集或個別 namespace 的存取，多使用者共用一叢集、各自 namespace 部署應用；管理員可檢視容器應用修訂歷史。

## 9. 內容管理 (Catalog)

- **Global / Distributed Catalogs**：跨多 vCenter / 多 VCD 站點同步維護一致的 vApp Template / ISO (透過共享儲存 / 複寫技術)。
- 支援 published / subscribed catalog 訂閱模型。

## 10. 部署與架構建議

- VCD cell 通常多節點 + 共用 NFS transfer share + 外部資料庫 (**PostgreSQL 13+**)。
- 前端可放 load balancer；多 cell 提供 HA。
- Appliance 基於 **Photon OS 4.0** (10.6)。
- 與 vCenter / NSX Manager 以 API 整併；在 VCF 環境疊於 SDDC 之上，並以 VCF 方案交付。

## 11. 規劃 Checklist

- [ ] 確認目標版本與 build (現最高 10.6.1.2 / Build 25088252，05 DEC 2025) 及與 vCenter / NSX 相容性 (以官方文件為準)
- [ ] 確認外部資料庫為 PostgreSQL 13 或更新版本
- [ ] 決定租戶層級 (兩層 vs 三層 Provider → Sub-Provider → Managed Org)
- [ ] PVDC 與底層 vCenter / 儲存 / NSX 對應
- [ ] OrgVDC 配置模型 (Flex / PAYG / Allocation / Reservation)
- [ ] IP Spaces 規劃 (IPv4 或 IPv6 分開、private / shared、配額與覆寫、BGP)
- [ ] IP Retention 保留期 (sub-provider / managed org 層級)
- [ ] Edge Gateway、Gateway Firewall (T0/T1)、Stateful Firewall 授權 (ANS)、DFW 策略
- [ ] Avi Load Balancer (含 IPv6 Transparent LB) 需求
- [ ] Catalog 散布策略 (含 Global / Distributed Catalogs)
- [ ] Guest OS-Aware VM Placement (VM Groups → host/cluster) 合規 / 授權需求
- [ ] API Token 強制到期 / 即時失效政策
- [ ] 是否導入 CSE / K8s 自助與 namespace 細粒度授權

## 來源

- https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-106-release-notes.html
- https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-1061-release-notes.html
- https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-10612-release-notes.html
- https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes.html
- https://blogs.vmware.com/cloudprovider/2025/02/vmware-cloud-director-10-6-1-is-here-whats-new.html
- https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/map-for-vmware-cloud-director-tenant-portal-guide-10-6/working-with-networks-tenant/working-with-ip-spaces-tenant.html
- https://knowledge.broadcom.com/external/article/325479/build-numbers-and-installer-versions-of.html
- https://www.virten.net/vmware/product-release-tracker/
