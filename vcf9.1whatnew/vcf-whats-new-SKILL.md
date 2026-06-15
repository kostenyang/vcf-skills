---
name: vcf-whats-new
description: Create Broadcom VCF "What's New" / product technical overview decks (Tech Tuesday style, L200) using the official VCF 9 Tech Tuesday template. Trigger whenever the user wants a feature overview, "What's New" briefing, product update, technical enablement deck, or feature deep-dive for vSphere / ESX / vCenter / VCF Operations / VCF 9.x — including new-feature roundups, DEMO-driven sessions, and capability showcases. Also trigger for 新功能介紹, What's New, 產品技術概覽, feature 簡報, tech enablement, Tech Tuesday. Always use TECH_TUESDAY_Whats_New_with_vSphere_in_VCF_9_1.pptx as the base template — never create from scratch.
---

# VCF "What's New" / Tech Overview Presentation Skill

Read `vcf-ppt-base` SKILL.md first for the general editing workflow.
Location: `/home/claude/broadcom-ppt-skills/vcf-ppt-base/SKILL.md`

> **⚡ 固定底版**：永遠使用 `TECH_TUESDAY_Whats_New_with_vSphere_in_VCF_9_1.pptx` (8.5MB)。
> **白底 content slides 為主**；section divider 與 DEMO 頁用品牌深色 VCF 9 視覺。
> 這是 **L200 產品功能概覽**範本（不是升級路徑範本 → 那個用 `vcf-91-upgrade`）。

Template GitHub URL:
`https://raw.githubusercontent.com/kostenyang/BroadcomPPT/main/vcf-whats-new/TECH_TUESDAY_Whats_New_with_vSphere_in_VCF_9_1.pptx`

Or from session uploads: `/mnt/user-data/uploads/TECH_TUESDAY_Whats_New_with_vSphere_in_VCF_9_1.pptx`

---

## When to use this vs other VCF skills

| 需求 | 用哪個 skill |
|------|-------------|
| 產品/功能「What's New」概覽、feature 介紹、技術 enablement、DEMO session | **vcf-whats-new** (本 skill) |
| 升級路徑、5.2.1→9.1、IP/DNS 規劃、converge/import | `vcf-91-upgrade` |
| 特定客戶垂直故事 (金融/電信/半導體/AI/混合雲) | `vcf-financial` / `vcf-telecom` / `vcf-semiconductor` / `vcf-ai` / `vcf-hybrid-cloud` |
| 單頁專案狀態報告 | `vcf-project-status` |

---

## Template Specs

**File**: `TECH_TUESDAY_Whats_New_with_vSphere_in_VCF_9_1.pptx` (29 slides, 134 layouts available)
**Aspect ratio**: 16:9 (12188825 × 6858000 EMU)
**Fonts**: Arial (heading + body). 繁中渲染用 **微軟正黑體 (Microsoft JhengHei) + Arial**。
**Background default**: White `#FFFFFF`
**Content level**: L200 — 適合任何 audience，預設 60 分鐘
**Footer logo**: `vmware by Broadcom`（所有 content 頁固定）

### Brand Colors (theme)

| Role | Hex | Usage |
|------|-----|-------|
| Teal | `#007B8C` | Primary accent, icons |
| Ocean Blue | `#005C8A` | Secondary, links |
| Sky Blue | `#0098C7` | Supporting color, icons |
| Green | `#61A60E` | Positive / "new" / checkmark icons |
| Plum | `#6C4B94` | Alternating icons, accents |
| Gold | `#F3BA16` | Callouts, "CRITICAL" badges |
| Navy | `#1B1D36` | Dark backgrounds (title / divider / DEMO) |
| White | `#FFFFFF` | Default slide background |

> Icon 圓圈固定循環 4 色：**Green → Sky Blue → Plum → Teal**（左到右），維持 Broadcom Tech Tuesday 一致觀感。

---

## Signature VCF 9 Layouts (本範本特色頁)

這些是這份範本獨有、要優先使用的版型：

| 用途 | Layout 名稱 | Layout 檔 | 說明 |
|------|------------|-----------|------|
| **封面** | `VCF-light-title-a` | slideLayout7 | VCF 9 齒輪 hero 圖 + 對角分割，淺底深色 |
| **章節分隔** | `Section Header 2 - VCF 9` | slideLayout92 | VCF 9 齒輪視覺 + 章節名（如 Lifecycle Management） |
| **DEMO 頁** | `Big Statement with Photo` | slideLayout129 | 深色背景 + 齒輪 + 「DEMO + 功能名」 |
| **結尾** | `vcf-close-b` | slideLayout90 | Thank You + SRC 連結 |
| **免責頁** | `Blank` | slideLayout69 | About This Presentation / Do Not Distribute |

### 內容頁版型（feature slides）

| 用途 | Layout 名稱 | Layout 檔 |
|------|------------|-----------|
| 3 icon 功能列 | `Three Icon - Fancy` / `Three Icon - Fancy - RBLF` | slideLayout40 / 43 |
| 4 icon 功能列 | `Four Icon - Fancy - RBLF` | slideLayout46 |
| 5 icon 功能列 | `Five Icon - Fancy` | slideLayout48 |
| 四象限 | `Four Square 1` | slideLayout50 |
| 內容 + 右側圖 | `1_Diagram with Content on Right` | slideLayout36 |
| 標題 + 子標 + 圖 | `Title and Subtitle` | slideLayout26 |
| 雙欄（左色塊） | `Two-Content Balanced Color on Left` | slideLayout30 |

> **RBLF 版**（Right Body Left Footer）= icon 列 + 右側補充說明文字，適合每個 icon 要展開 1–2 句時。
> 純 icon 列（無右側文字）用非 RBLF 版。

---

## Feature-Slide 內容模型 (核心)

每張功能頁固定三層結構，照抄這個 pattern：

```
┌─ Benefit Headline (上方，價值陳述) ──────────────┐
│  例：Rapid Rollout of vCenter Security Patches   │
├─ Feature Name (副標，產品/功能名) ───────────────┤
│  例：vCenter Quick Patch                          │
├─ Capability points (3–5 個 icon 或 bullet) ──────┤
│  • Minimal – sometimes zero – downtime           │
│  • Only services patched need a restart          │
│  • vCenter operations continue during patching   │
└──────────────────────────────────────────────────┘
```

規則：
- **Headline 講「客戶得到什麼好處」**，不是功能名本身。Feature name 放副標。
- Capability point **3 個用 Three Icon、4 個用 Four Icon、5 個用 Five Icon**；超過 5 個拆兩頁。
- 需要架構/流程圖時用 `1_Diagram with Content on Right`（圖在左、要點在右）。
- 重大功能後面接一張 **DEMO 頁**（`Big Statement with Photo`，深色 + 「DEMO + 功能名」）。

---

## Standard Deck Structure (照搬參考 deck)

1. **About This Presentation / Disclaimer** — `Blank` (Do Not Distribute + 作者 + SRC 連結)
2. **Title Slide** — `VCF-light-title-a`（What's New With <產品> in VCF 9.x + 講者 + 日期）
3. **Section divider** — `Section Header 2 - VCF 9`（依主題分章，如 Lifecycle / VM Management / Workload Acceleration）
   - 每章 = 數張 feature 頁（icon 列 + diagram 頁交錯）
   - 重點功能後插一張 **DEMO** 頁
4. （重複 section divider + feature 頁，照功能主題分組）
5. **Thank You / Closing** — `vcf-close-b`（Thank You + SRC URL）

> 參考 deck 的三大章節分組（可直接沿用為任何 VCF 9 What's New 的骨架）：
> **Lifecycle Management** → **VM Management** → **Workload Acceleration**。

---

## 參考 Deck 功能清單 (vSphere in VCF 9.1，可當素材庫)

### Lifecycle Management
- Quickest Upgrade Path to VCF 9.1（vCenter/ESX/Ops 8.x→9.1 路徑圖）
- vCenter Quick Patch（快速安全修補，近乎零停機）— **DEMO**
- vCenter Lifecycle（RDU Online Depot / Re-size API / 虛擬硬體升級 / 維護通知）
- ESX Maintenance（ZTP / Image Checksum / Firmware & Driver Checks without HSM）
- Zero Touch Provisioning（UEFI HTTPS Boot、TPM/Secure Boot、無 TFTP）— **DEMO**
- ESX Live Patch（預設啟用 / TPM 支援 / 擴大涵蓋）
- vSphere Configuration Profiles（自動修復 / vSAN 整合 / Memory Tiering 設定 / VDS Bootstrap）
- Automatic TLS Certificate Renewal（vCenter/ESX 憑證、升級時 VMCA 換發）
- vCenter Performance（操作效能 +25% / 大規模備份 / 使用率監控 API / 新告警）

### VM Management
- Guest OS Customization（強化 / IPv6-only / 僅網路客製）
- DRS Optimized Maintenance Mode Evacuation（運算需求不足時延後撤離、重新平衡）
- DRS Parallel Processing of vMotion Tasks（平行 vMotion，縮短遷移時間）

### Workload Acceleration
- Enhanced Memory Tiering（可觀測性 / 冗餘選擇 / 設定流程 / 互通性 / 效能）
- Memory Tiering Software Mirroring（NVMe 成對鏡射，無需特殊硬體）— **DEMO**
- Offload Encrypted vMotion to Intel QAT（卸載加解密、釋放 CPU 核心）
- Topology Aware Scheduler（更佳 NUMA 放置、支援多核 CPU）
- AMD Hardware Enablement（MI350X GPU / Enhanced Direct Path I/O / IOMMU）
- NVIDIA Hardware Enablement（硬體加速 NIC / GPU-to-GPU RoCE / GPU 整合）

---

## VCF 9.1 Naming Conventions

| Old Name | VCF 9.1 Name |
|----------|-------------|
| Aria Operations | VCF Operations |
| Aria Automation | VCF Automation |
| Aria Operations for Networks | VCF Operations for Networks |
| Aria Operations for Logs | VCF Operations for Logs |
| vSphere with Tanzu / TKG | VKS |
| VCDA | Live Recovery |
| NSX-T | NSX |
| SDDC Manager | SDDC Manager (unchanged) |

---

## ⚠️ Distribution / 機密性

範本第 1 頁是 **"Do Not Distribute This Presentation"** Broadcom 內部聲明。
- 對外（客戶/VMUG/Explore）版本：**移除 speaker notes**，並改用可留存的 PDF（SRC 上有對外 PDF 版）。
- 內部 enablement：保留 disclaimer 頁與 speaker notes。
- 客製給特定客戶時，**先換掉封面標題/講者/日期**，刪掉不相關功能頁。

---

## Speaker Notes Guidelines (中文)

- **每張 feature 頁**：1 句帶到「這功能解決客戶什麼痛點」，再講 2–3 個技術細節。
- **DEMO 頁**：寫 demo 環境前置條件（版本、需求），避免現場才發現不支援。
- **Upgrade Path 頁**：強調這是「最快取得 VCF 9.1 能力」的路徑（先升 Ops，再升 vCenter/ESX）。
- **AI/硬體頁 (AMD/NVIDIA)**：標註支援的 GPU/CPU 型號，提醒客戶查 HCL。
- 一律 **conclusion-first**、英文技術名詞 + 中文敘述。

---

## Token / 成本最佳化（沿用既有規則）

- **內容草稿與檔案生成分開**：先在對話確認所有 feature 頁文字，再一次生成 .pptx。
- 大型 deck（>20 頁）分多個對話產出，避免單次 token 爆量。
- **Front-load 需求**：一開始就講清楚要哪些 section、哪些 feature、要不要 DEMO 頁、對內或對外版本。
- 模板型 deck 用標準 chat + `vcf-*` skill，**不要用 Cowork**。
