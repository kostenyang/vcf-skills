# VMware Cloud Foundation 升級指南（VCF-升級指南.md）

> 涵蓋 VCF 的四種路徑：Deploy / Converge / Import / Upgrade，聚焦 VCF 5.x → 9.0.x 與 → 9.1。
> 文件日期基準：2026-05-31。所有版本號、數字與限制以官方 techdocs Release Notes 為最終依據。

## 目錄

1. [總覽：四種路徑](#1-總覽四種路徑)
2. [VCF 9.0 部署典範轉移](#2-vcf-90-部署典範轉移)
3. [Upgrade：5.2 → 9.0 升級](#3-upgrade52--90-升級)
4. [Converge：vSphere → VCF 收斂](#4-convergevsphere--vcf-收斂)
5. [Import：既有 vCenter 匯入](#5-import既有-vcenter-匯入)
6. [VCF 9.1 升級](#6-vcf-91-升級)
7. [授權變更](#7-授權變更)
8. [過時認知更正](#8-過時認知更正)
9. [FAQ](#9-faq)
10. [升級前置作業 Checklist](#10-升級前置作業-checklist)
11. [參考來源](#11-參考來源)

---

## 1. 總覽：四種路徑

VCF 9.0 起，部署流程改變，大多數元件改用 **VCF Installer** 與 **VCF Operations** 工作流程安裝，不再走舊式 SDDC Manager 全自動 bring-up。官方文件以**管理網域 (Management Domain)** 作為建立 VCF 執行個體的最小邏輯單位。

| 路徑 | 情境 | 重點 |
|---|---|---|
| **Deploy** | 全新 / Greenfield，建立全新 VCF Fleet/執行個體 | 可直接部署至 9.0.2，無須中間版本；VCF Installer 處理初始元件，其餘安裝後手動完成。 |
| **Converge** | 將獨立 vSphere 轉為 VVF 或 VCF | 須符合最低版本與收斂順序（先管理平面，再核心 SDDC）；提供 pre-convergence 選項，可先獨立升級元件並享 90 天評估期。 |
| **Import** | 將既有 vCenter 匯入為 Workload Domain | 於管理網域建立後執行；NSX 4.x 可先以 WLD 匯入再升級。 |
| **Upgrade** | VCF 5.x → 9.0.x / 9.1 | 先升級管理平面，再依序升級核心 SDDC 元件。 |

---

## 2. VCF 9.0 部署典範轉移

VCF 9.0 相對於 5.x 的重大變更，直接影響升級與收斂：

- 部署改以 **VCF Installer + VCF Operations** 工作流程為核心。
- **VCF Operations 成為強制元件**；Aria Lifecycle 更名為 **VCF Fleet Management**。
- 移除 **vLCM baselines**，全面改用 **vLCM images**。
- **ELM (Enhanced Linked Mode) 不再支援**，功能由 VCF Operations 接手。
- 管理網域**主要儲存 (principal storage)** 擴展為 **vSAN / Fibre Channel / NFS**（不再強制只能 vSAN）。
- **授權集中**由 VCF Operations 跨 fleet 管理（透過 VCF Business Services console）。
- **VMware Cloud Director (VCD) 不支援**，且無官方遷移路徑。

---

## 3. Upgrade：5.2 → 9.0 升級

### 3.1 升級順序（必背）

```
VCF Operations 元件 → SDDC Manager → NSX → vCenter → ESX hosts
```

### 3.2 關鍵前提

- **vLCM image 必備**：所有 ESX cluster 必須在 ESX 升級階段前，由 baseline 轉換為 vLCM image。VCF 9.0 不支援 baselines。
- **VCF Operations 強制部署**：即使原本未用 LCM/Aria Suite，升級時仍會部署 Aria Lifecycle（VCF Fleet Management）與 VCF Operations。
- **Aria Suite 不需 decouple**：可先升級至 VCF 9 相容版本再續行。
- **無完整 rollback**：以每階段元件層級備份作為個別失敗的回復檢查點。

### 3.3 整併式 (Consolidated) 設計主機數

- 建議最少 **4 台**（vSAN 最少 3 台）。
- 外部儲存最少 **2 台**。
- 上限：每 cluster **96 hosts**、每 vCenter **2,500 hosts**。

### 3.4 vSAN OSA

vSAN OSA (Original Storage Architecture) **仍受支援、未被棄用**；既有硬體可續用，但須驗證硬體 / 韌體相容性。

---

## 4. Converge：vSphere → VCF 收斂

將獨立 vSphere 收斂為 VVF 或 VCF。收斂前會驗證 storage / network / compute、硬體、switch 版本與預設值是否符合 VCF 建議組態。

### 4.1 版本需求

| 目標 | vCenter 最低 | ESX 最低 | NSX |
|---|---|---|---|
| VCF 9.0.0（不含 NSX） | 9.0.0 | 9.0.0 | 不支援收斂，必須全新部署 |
| VCF 9.0.1（不含 NSX） | 9.0.1 | 9.0.1 | 全新部署 |
| VCF 9.0.2（不含 NSX） | 9.0.2 | 9.0.2 | 全新部署 |
| 含 NSX 收斂（9.0.1 / 9.0.2） | 8.0 Update 3 | 8.0 Update 1 | NSX 最低 4.2.1 |

### 4.2 收斂前必辦

- **停用 ELM**：VCF 9 不支援 ELM，收斂前必須先停用；功能由 VCF Operations 接手。
- **修正 DVS 組態**：移除 ELM 或將 Distributed Virtual Switch 升級至受支援版本。
- **確認主要儲存**：VCF 9 支援 vSAN / Fibre Channel / NFS。
- **收斂順序**：先管理平面，再核心 SDDC 元件。
- **pre-convergence 選項**：可先獨立升級元件到 9.0.x，享 90 天評估期。

---

## 5. Import：既有 vCenter 匯入

將既有 vCenter 匯入為 Workload Domain，於管理網域建立後執行。NSX 4.x 部署可先以 WLD 匯入再升級。

### 5.1 版本需求（所有版本）

| 元件 | 最低需求 |
|---|---|
| 目標 VCF | 9.0.x |
| vCenter | 8.0 Update 1 以上 |
| ESX | 8.0 Update 1 以上 |
| NSX | 4.1.0.2 以上 |

匯入前同樣須先停用 ELM。

---

## 6. VCF 9.1 升級

VCF 9.1 於 **2026/5/5 GA**（release notes 對應 9.1.0.0）。

### 6.1 來源版本與範圍

- **來源**：可從 VCF 5.2.x（序列或 skip-level）或 VCF 9.0.x（直接升級）升至 9.1；早於 5.2 須先升至 5.2.x。
- **強制範圍**：升 9.1 時，fleet 層級與管理網域元件必須升至 9.1；**工作負載網域升級非強制，可作為 Day-N**。

### 6.2 升級序列

- 5.2.x→9.1 與 9.0.x→9.1 皆為約 **23 個有序步驟**。
- 9.0.x→9.1 第一步通常為將 **VCF Identity Broker 轉移到管理網路**（若原部署於 NSX overlay segment）。

### 6.3 新元件

- **VCF Management Services**：整合 Fleet lifecycle 與 SDDC lifecycle。
- **License Server**：VCF 執行個體授權所必需。
- 9.0 的 vIDB 外部多節點 appliance cluster 於 9.1 **直接遷入 VCF Management Services**，原獨立 VM 關機後可除役。
- VCF Operations / Operations for logs/networks / Automation / Identity Broker 的生命週期管理，於 VCF Operations 升至 9.1 時轉移到新的 fleet/SDDC lifecycle 元件。

### 6.4 IP / CIDR 規劃（以官方文件為準）

- VCF Management Services 部署最少需 **12 個 IP**。
- VCF services runtime 預設內部 CIDR 為 **198.18.0.0/15**；若與現網衝突，須改為 **240.0.0.0/15** 或 **250.0.0.0/15**。

### 6.5 已知問題

- 若 9.0.x 的 Identity Broker 部署在**非管理網路**，升級至 9.1 會失敗。
- vCenter **in-place 升級 (9.0.x→9.1.0)** 後，**VM 硬體版本需手動升級**。

### 6.6 VCF 9.1 Upgrade Planning Tool

2026/5/28 公布。依現況（vSphere 或 VCF、現有版本）給出可行升級目標、分階段工作流程、資源與網路需求、注意事項與文件連結，並可匯出 PDF。

> 工具網址：<https://vmware.github.io/vcf-upgrade-planner/>

---

## 7. 授權變更

- 自 VCF 與 vSphere Foundation 9.0 起，授權改由 **VCF Operations 跨整個 fleet 管理**（透過 VCF Business Services console）。
- VCF 9.1 另引入專屬 **License Server**。

---

## 8. 過時認知更正

| 過時認知 | 正確說法 |
|---|---|
| VCF 部署一定走 SDDC Manager bring-up | 9.0 起改以 VCF Installer + VCF Operations 工作流程為主；SDDC Manager 在收斂過程中部署 |
| 升級不一定要 Aria/Operations | VCF Operations 為 9.0 強制元件，必定部署 |
| ESX 可續用 vLCM baselines | 9 僅支援 vLCM images，升級前須轉換 |
| ELM 可沿用 | 9 不支援 ELM，匯入/收斂前須停用 |
| vIDM 可升級為新身分服務 | vIDM→VIDB 無直接升級/遷移路徑，須 greenfield 部署 VIDB |
| 管理網域只能用 vSAN | 9 支援 vSAN / FC / NFS |
| VCD 可移轉至 VCF 9 | 不支援且無官方遷移路徑 |
| vSAN OSA 已棄用 | OSA 仍受支援，須驗證硬體/韌體相容性 |

---

## 9. FAQ

**Q1. 5.2 → 9.0 升級順序？**
VCF Operations → SDDC Manager → NSX → vCenter → ESX hosts。

**Q2. 一定要轉 vLCM image 嗎？**
是。所有 ESX cluster 在 ESX 升級階段前必須由 baseline 轉換為 vLCM image，9.0 不支援 baselines。

**Q3. 沒用 Aria，也要部署 VCF Operations 嗎？**
要。VCF Operations 為 9.0 強制元件，升級時必定部署（含更名後的 VCF Fleet Management）。

**Q4. 升級前要備份什麼？**
SDDC Manager 以外部 SFTP 備份；vCenter 升級前做 file-based backup。

**Q5. vSAN OSA 還能用嗎？**
能。仍受支援、未棄用，既有硬體可續用，須驗證硬體/韌體相容性。

**Q6. 升級失敗能 rollback 嗎？**
無完整 rollback 機制；以每階段元件層級備份作為個別失敗的回復檢查點。

**Q7. vIDM 怎麼處理？**
vIDM → VIDB (VMware Identity Broker) 無直接升級/遷移路徑，須 greenfield 部署 VIDB。

**Q8. VMware Cloud Director 能升到 VCF 9 嗎？**
不能。VCF 9.0 不支援 VCD，且無官方遷移路徑。

**Q9. 收斂含 NSX 的最低版本？**
vCenter 8.0 Update 3、ESX 8.0 Update 1、NSX 4.2.1（目標 VCF 9.0.1 / 9.0.2）。

**Q10. 9.1 升級時 WLD 一定要一起升嗎？**
不必。fleet 層與管理網域為強制範圍，WLD 升級可延後為 Day-N。

**Q11. 9.0.x→9.1 第一步常見是什麼？**
若 Identity Broker 部署於 NSX overlay segment，第一步通常為將其轉移到管理網路（否則升級會失敗）。

---

## 10. 升級前置作業 Checklist

- [ ] 以外部 SFTP 備份 SDDC Manager。
- [ ] vCenter 升級前做 file-based backup。
- [ ] 確認無進行中的網域操作（建立/擴充/縮減 WLD）。
- [ ] 確認無失敗工作流程、無資源處於 activating/error 狀態（若有先聯絡 VMware Support）。
- [ ] 下載並執行 precheck，通過後才可升級。
- [ ] 將所有 ESX cluster 由 baseline 轉換為 vLCM image。
- [ ] 確認硬體/韌體相容性（含 vSAN OSA 既有硬體）。
- [ ] 收斂/匯入前停用 ELM、修正 DVS 組態。
- [ ] 規劃每階段元件層級備份作為回復檢查點（無完整 rollback）。
- [ ] 9.1：確認 Identity Broker 位於管理網路；規劃 VCF Management Services IP/CIDR；預期 vCenter in-place 升級後手動升 VM 硬體版本。
- [ ] 使用 VCF 9.1 Upgrade Planning Tool 產出分階段工作流程與資源/網路需求。

---

## 11. 參考來源

- Deploy / Converge / Upgrade 總覽：<https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/deployment/overview-of-deploy--converge--and-upgrade.html>
- 升級 VCF (9.1)：<https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/upgrading-cloud-foundation.html>
- VCF 9.1.0.0 Release Notes：<https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes.html>
- 升級序列與相關問題 (KB 440630)：<https://knowledge.broadcom.com/external/article/440630/upgrade-sequence-and-related-issues-for.html>
- 5.2→9.0 Top 10 問答：<https://blogs.vmware.com/cloud-foundation/2025/12/18/upgrading-vmware-cloud-foundation-5-2-to-9-0-the-top-10-questions-answered/>
- 5.2→9.0 Webinar 重點：<https://blogs.vmware.com/cloud-foundation/2025/11/20/upgrading-vmware-cloud-foundation-5-2-to-9-0-webinar-takeaways/>
- Converge Top 10 問答：<https://blogs.vmware.com/cloud-foundation/2026/04/16/converging-vmware-vsphere-to-vmware-cloud-foundation-9-0-the-top-10-questions-answered/>
- 如何收斂 vSphere 至 VCF 9.0：<https://blogs.vmware.com/cloud-foundation/2026/02/05/how-to-converge-a-vmware-vsphere-environment-to-vmware-cloud-foundation-9-0/>
- VCF 9.1 Upgrade Planning Tool 公告：<https://blogs.vmware.com/cloud-foundation/2026/05/28/announcing-the-vmware-cloud-foundation-9-1-upgrade-planning-tool/>
- VCF 9.1 GA 公告：<https://blogs.vmware.com/cloud-foundation/2026/05/05/announcing-vcf-9-1-modern-private-cloud-built-for-efficiency-and-resilience/>
