---
name: vcf-whats-new
description: Create Broadcom VCF "What's New" / product technical overview decks (Tech Tuesday style, L200–L300) using the official VCF 9 Tech Tuesday templates. Trigger whenever the user wants a feature overview, "What's New" briefing, product update, technical enablement deck, or feature deep-dive for vSphere / ESX / vCenter / vSAN / storage / data protection / VCF Operations / VCF 9.x — including new-feature roundups, DEMO-driven sessions, and capability showcases. Also trigger for 新功能介紹, What's New, 產品技術概覽, feature 簡報, tech enablement, Tech Tuesday, vSAN 新功能, 儲存新功能. Always start from one of the two official Tech Tuesday base decks — never create from scratch.
---

# VCF "What's New" / Tech Overview Presentation Skill

Read `vcf-base` SKILL.md first for the general editing workflow.
Location: `/home/claude/broadcom-ppt-skills/vcf-base/SKILL.md`

> **⚡ 固定底版：兩份 Tech Tuesday 來源 deck，依主題二選一**（都不從零開始）。
> **白底 content slides 為主**；section divider、DEMO、封面、結尾用品牌深色 / Plum 視覺。
> 這是 **產品功能概覽**範本（不是升級路徑範本 → 那個用 `vcf-upgrade`）。

## 底版二選一

| 主題 | 底版 | 頁數 | 風格 | 深度 |
|------|------|------|------|------|
| vSphere / ESX / vCenter / 生命週期 / 平台 | `TECH_TUESDAY_Whats_New_with_vSphere_in_VCF_9_1.pptx` (8.5MB) | 29 | **icon-led** — icon 列為主，VCF 9 齒輪視覺 | L200 |
| **vSAN / 儲存 / 資料保護 / 網路 / VKS** | `TECH_TUESDAY_Whats_New_with_vSAN_in_VCF_9_1.pptx` (12.2MB) | 30 | **diagram-led** — 左圖右文為主，**Plum** 視覺 | L300 |

Template GitHub URLs:
- `https://raw.githubusercontent.com/kostenyang/BroadcomPPT/main/TECH_TUESDAY_Whats_New_with_vSphere_in_VCF_9_1.pptx`
- `https://raw.githubusercontent.com/kostenyang/BroadcomPPT/main/TECH_TUESDAY_Whats_New_with_vSAN_in_VCF_9_1.pptx`

Or from session uploads: `/mnt/user-data/uploads/<檔名>`

> **選底版的判準**：內容以「一句話能講完的功能點」為主 → 用 vSphere 版（icon 列）。
> 內容需要**架構圖 / 拓撲 / before-after 對照**才講得清楚 → 用 vSAN 版（左圖右文）。
> 混合主題以佔比高的那種為準，另一種版型從對方 deck 複製 slide 進來即可（兩份共用同一套 master 版型庫）。

---

## When to use this vs other VCF skills

| 需求 | 用哪個 skill |
|------|-------------|
| 產品/功能「What's New」概覽、feature 介紹、技術 enablement、DEMO session | **vcf-whats-new** (本 skill) |
| 升級路徑、5.2.1→9.1、IP/DNS 規劃、converge/import | `vcf-upgrade` |
| 特定客戶垂直故事 (金融/電信/半導體/AI/混合雲) | `vcf-financial` / `vcf-telecom` / `vcf-semiconductor` / `vcf-ai` / `vcf-hybrid-cloud` |
| 單頁專案狀態報告 | `vcf-project-status` |

---

## ⚠️ Layout 一律用「名稱」解析，不要用編號

兩份底版共用同一套 Broadcom 版型庫，但 **`slideLayoutNN.xml` 的編號在不同 deck 完全不同**
（例：`slideLayout92` 在 vSphere 版是 `Section Header 2 - VCF 9`，在 vSAN 版是 `Section - Availability`）。

動任何 slide 前先建立「名稱 → 檔名」對照：

```bash
for f in unpacked/ppt/slideLayouts/slideLayout*.xml; do
  printf '%s | %s\n' "$(basename $f)" \
    "$(sed -n 's/.*<p:cSld[^>]*name="\([^"]*\)".*/\1/p' $f | head -1)"
done | sort -t'|' -k2
```

本 skill 下面所有表格都以**版型名稱**為準；編號僅供 vSAN 底版參考。

---

## Template Specs

**Aspect ratio**: 16:9 (12188825 × 6858000 EMU) — 兩份相同
**Theme**: `VMware 2025 Light`（clrScheme `VMware-Light`）為主 master；第二 master 用 `VMware-dark`
**Fonts**: Arial (major + minor)。deck 內嵌 **Metropolis / Metropolis Light / Arial Rounded MT Bold**（標題視覺用）。
繁中渲染用 **微軟正黑體 (Microsoft JhengHei) + Arial**；theme 已把 Hant script 指到微軟正黑體。
**Background default**: White `#FFFFFF`
**Footer logo**: `vmware by Broadcom`（所有 content 頁固定）；頁碼固定右下 (11490941, 6464808)
**Masters**: 2 個 master —— master1 = 98 layouts（主要使用，含所有 Section - <主題> 版型）、master2 = 42 layouts（精簡備用）

### Brand Colors — Light theme (`VMware-Light`，預設)

| Role | Scheme slot | Hex | Usage |
|------|-------------|-----|-------|
| Teal | accent1 | `#007B8C` | Primary accent, icons |
| Ocean Blue | accent2 | `#005C8A` | 標題文字色、**內容頁上方細色條**、links |
| Sky Blue | accent3 | `#0098C7` | Supporting color, icons, hyperlink |
| Green | accent4 | `#61A60E` | Positive / "new" / checkmark icons |
| Plum | accent5 | `#6C4B94` | 封面 / section / 結尾主視覺（vSAN 底版走這條）|
| Gold | accent6 | `#F3BA16` | Callouts, "CRITICAL" badges |
| Navy | dk2 | `#1B1D36` | Dark backgrounds (title / divider / DEMO) |
| Light Grey | lt2 | `#EEEEEE` | 淺色區塊底 |
| Diagram Grey | — | `#717074` | **架構圖線條 / 邊框固定色**（不要改用黑色）|
| White | lt1 | `#FFFFFF` | Default slide background |

### Brand Colors — Dark theme (`VMware-dark`，深底頁用)

深底 section / DEMO / 封面頁走第二 master，accent 換成高彩度版本：

| Role | Hex |
|------|-----|
| Bright Blue (accent1) | `#0088EF` |
| Cyan (accent2) | `#01B9C6` |
| Sky Blue (accent3) | `#0098C7` |
| Green (accent4) | `#61A60E` |
| Light Plum (accent5) | `#A468EE` |
| Gold (accent6) | `#F3BA16` |

> **不要**在深底頁沿用淺底的 `#007B8C` / `#6C4B94`，對比不足。用上表的 dark 版。

> Icon 圓圈固定循環 4 色：**Green → Sky Blue → Plum → Teal**（左到右），維持 Broadcom Tech Tuesday 一致觀感。

### ⚠️ 配色不要單調 — 每章換一個 accent

**細色條、section divider、icon 圈的顏色跟著「章」走，不是全 deck 固定一色。**
四個 pillar 就配四個 accent（建議 Teal → Sky Blue → Plum → Green），整份至少四種主色。

架構圖裡的元件用 `vcf-base` 的 **extended palette** 分類（`#78BE20` 綠 / `#0091A0` 青 / `#0095D3` 藍 /
`#A68CC2` 薰衣草 / `#E68C28` 橘 / `#A6192E` 緋紅…），每頁 3–5 個彩色，同一種元件跨頁用同一色。
橘=變更中、紅=風險/不支援、綠=新增，語意色不要拿來當分類色。

> 完整規則（三層色彩結構、extended palette 全表、禁忌）見 `vcf-base` 的「配色運用」段。

---

## Signature Layouts

### A. vSphere 底版（icon-led）

| 用途 | Layout 名稱 | 說明 |
|------|------------|------|
| **封面** | `VCF-light-title-a` | VCF 9 齒輪 hero 圖 + 對角分割，淺底深色 |
| **章節分隔** | `Section Header 2 - VCF 9` | VCF 9 齒輪視覺 + 章節名 |
| **DEMO 頁** | `Big Statement with Photo` | 深色背景 + 齒輪 + 「DEMO + 功能名」 |
| **結尾** | `vcf-close-b` | Thank You + SRC 連結 |
| **免責頁** | `Blank` | About This Presentation / Do Not Distribute |

內容頁：`Three Icon - Fancy` / `Four Icon - Fancy - RBLF` / `Five Icon - Fancy` / `Four Square 1` /
`Diagram with Content on Right` / `Title and Subtitle` / `Two-Content Balanced Color on Left`

> **RBLF 版**（Right Body Left Footer）= icon 列 + 右側補充說明文字，適合每個 icon 要展開 1–2 句時。
> 純 icon 列（無右側文字）用非 RBLF 版。

### B. vSAN 底版（diagram-led，**Plum**）

| 用途 | Layout 名稱 | (vSAN 檔號) | 說明 |
|------|------------|------------|------|
| **封面** | `Title Slide – Plum with Circle` | slideLayout6 | 左側 Plum 圓形 hero，右側標題 40pt + 講者/職稱/單位 16/16/14pt |
| **PowerPoint 警語** | `Actually Blank` | slideLayout64 | 「OPEN ALL SLIDE DECKS WITH POWERPOINT」全頁警語 |
| **免責頁** | `Blank` | slideLayout63 | Do Not Distribute + Author / Content Type / Time to Present |
| **一頁總覽** | `Title Only` | slideLayout24 | 四欄 pillar × 各 3–5 條 feature bullet（全 deck 縮影）|
| **章節分隔** | `Section Header – Plum` | slideLayout14 | 左標題 36pt (accent2) + 副標，右側 Plum freeform 圖形 |
| **主力內容頁** | `Diagram with Content on Right` | slideLayout34 | **本底版 30 頁中用了 17 頁** — 左圖右文 |
| **對照/成效頁** | `Diagram with Outcome, Benefit` | slideLayout35 | 圖 + outcome/benefit 兩欄 |
| **密集內容頁** | `Title, Subtitle and Content` | slideLayout26 | 表格 / 多欄清單 |
| **收尾論述頁** | `Blank` | slideLayout63 | 自由排版的 value statement |
| **結尾** | `Thank You / Closing - Plum` | slideLayout82 | |

**主題式 section divider**（master1 獨有，直接照主題選，不必自己改字）：
`Section - Storage` / `Section - Networking` / `Section - VKS` / `Section - DPU` / `Section - AI` /
`Section - Lifecycle` / `Section - Workloads` / `Section - Resource Mgmt` / `Section - Availability` /
`Section - Developer` / `Section - Wrap Up`

---

## Feature-Slide 內容模型 (核心)

兩種 pattern，**同一份 deck 內不要混用超過兩種**。

### Pattern A — icon 列（vSphere 底版預設）

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

- Capability point **3 個用 Three Icon、4 個用 Four Icon、5 個用 Five Icon**；超過 5 個拆兩頁。

### Pattern B — 左圖右文（vSAN 底版預設，`Diagram with Content on Right`）

```
 Title    : Benefit Headline（客戶得到什麼）        ← title placeholder
 Subtitle : Feature Name / 一句技術描述 16–20pt     ← subTitle idx=10，橫跨整頁寬
 ┌──────────────────────────┬──────────────────┐
 │                          │ ▔▔▔▔▔▔▔▔ ← accent2 細色條
 │   架構圖 / 拓撲 / 對照圖   │ • bullet 1       │
 │   (7398303 × 4572000 EMU) │ • bullet 2       │  body idx=17
 │   線條色固定 #717074       │ • bullet 3       │  (3808412 EMU 寬)
 │                          │ • bullet 4       │
 └──────────────────────────┴──────────────────┘
```

幾何（EMU，照抄不要自己調）：
- Subtitle：off (592866, 811830) ext (10962687, 247743)，sz 16–20pt
- 左圖區：off (608012, 1600201) ext (7398303, 4572000)
- 右欄細色條：off (8380072, 1589923) ext (3808754, 82618)，填色 = **該章的 accent**（範本預設 `accent2`，逐章換色）
- 右欄文字：off (8380413, 1600200) ext (3808412, 4572000)，sz 11–16pt

規則：
- **Headline 講「客戶得到什麼好處」**，不是功能名本身。Feature name 放副標。
  - ✅ `Better Space Efficiency through Improved Data Compression` / 副標 `vSAN ESA inline compression improvements…`
  - ✅ `Deploy vSAN without Purchasing New Servers` / 副標 `Repurposing vSphere hosts for VMware vSAN`
  - ❌ 標題直接寫 `Auto-RAID in vSAN`（那是副標的料）
- 右欄 **3–5 條**，每條 1 行為佳、最多 2 行；關鍵詞用 **bold** 局部強調（整條不要全粗）。
- 圖內文字 9–12pt，元件框線一律 `#717074`，避免純黑。
- 重大功能後面接一張 **DEMO 頁**（`Big Statement with Photo`，深色 + 「DEMO + 功能名」）。

---

## Standard Deck Structure

### 變體 A — vSphere 底版

1. **About This Presentation / Disclaimer** — `Blank`
2. **Title Slide** — `VCF-light-title-a`
3. **Section divider** — `Section Header 2 - VCF 9`，每章數張 feature 頁（icon 列 + diagram 頁交錯），重點功能後插 **DEMO** 頁
4. （重複）
5. **Thank You / Closing** — `vcf-close-b`

> 三大章節分組可直接沿用：**Lifecycle Management** → **VM Management** → **Workload Acceleration**。

### 變體 B — vSAN 底版（30 頁，建議照抄骨架）

1. **Title Slide** — `Title Slide – Plum with Circle`（標題 + 講者 email + 職稱 + 單位）
2. **PowerPoint 警語頁** — `Actually Blank`（Google Slides 會破壞字型/排版）
3. **Do Not Distribute 頁** — `Blank`（Author / Content Type (L300) / Time to Present / SRC PDF 連結）
4. **一頁總覽** — `Title Only`：四欄 = 四個 pillar，每欄 3–5 條 feature bullet
5. **Pillar 1 section** — `Section Header – Plum`（標題 = pillar 名，副標 = 一句價值陳述）
6. 該 pillar 的 feature 頁 ×4–6（`Diagram with Content on Right` 為主，密集內容用 `Title, Subtitle and Content`）
7. （重複 5–6，共 **4 個 pillar**）
8. **收尾論述頁** — `Blank`：一句 provocative statement + 支撐句
9. **Thank You / Closing** — `Thank You / Closing - Plum`

> **四 pillar 骨架**（任何儲存/平台 What's New 都能沿用）：
> **Flexible & Efficient <X> Platform**（省成本）→ **Accelerated Modern Application Development**（開發者/雲原生）
> → **Secure and Cyber Resilient <X>**（安全/勒索復原）→ **Simplified Operations**（維運簡化）
>
> 每個 pillar 的副標一律一句大白話：`Drive down hardware costs` / `Delivering new capabilities and outcomes`
> / `Easily protect and secure your data` / `Making storage easier and more intuitive`

---

## 參考 Deck 功能清單（素材庫）

### vSphere in VCF 9.1

**Lifecycle Management**
- Quickest Upgrade Path to VCF 9.1（vCenter/ESX/Ops 8.x→9.1 路徑圖）
- vCenter Quick Patch（快速安全修補，近乎零停機）— **DEMO**
- vCenter Lifecycle（RDU Online Depot / Re-size API / 虛擬硬體升級 / 維護通知）
- ESX Maintenance（ZTP / Image Checksum / Firmware & Driver Checks without HSM）
- Zero Touch Provisioning（UEFI HTTPS Boot、TPM/Secure Boot、無 TFTP）— **DEMO**
- ESX Live Patch（預設啟用 / TPM 支援 / 擴大涵蓋）
- vSphere Configuration Profiles（自動修復 / vSAN 整合 / Memory Tiering 設定 / VDS Bootstrap）
- Automatic TLS Certificate Renewal（vCenter/ESX 憑證、升級時 VMCA 換發）
- vCenter Performance（操作效能 +25% / 大規模備份 / 使用率監控 API / 新告警）

**VM Management**
- Guest OS Customization（強化 / IPv6-only / 僅網路客製）
- DRS Optimized Maintenance Mode Evacuation
- DRS Parallel Processing of vMotion Tasks

**Workload Acceleration**
- Enhanced Memory Tiering（可觀測性 / 冗餘選擇 / 設定流程 / 互通性 / 效能）
- Memory Tiering Software Mirroring（NVMe 成對鏡射）— **DEMO**
- Offload Encrypted vMotion to Intel QAT
- Topology Aware Scheduler
- AMD Hardware Enablement（MI350X GPU / Enhanced Direct Path I/O / IOMMU）
- NVIDIA Hardware Enablement（硬體加速 NIC / GPU-to-GPU RoCE / GPU 整合）

### vSAN in VCF 9.1

**Flexible & Efficient Storage Platform**（Drive down hardware costs）
- Better Space Efficiency through Improved Data Compression（vSAN ESA inline ZSTD、4KB block）
- Cost Efficient Storage Environments for Cyber Recovery（cyber recovery 專用 ReadyNodes）
- Reduce Storage Costs with Lower Hardware Requirements（small/medium/large 三種 profile）
- Greater Flexibility with Remote vSAN Datastores（ESA/OSA 混掛 remote datastore）
- Minimize Operational Downtime for Clustered Applications（shared VMDK hot-extend）
- Lower Costs and Increase Utilization in vSAN Hosts（NVMe advanced memory tiering）
- Deploy vSAN without Purchasing New Servers（既有 vSphere 主機改用 vSAN 授權）

**Accelerated Modern Application Development**（Delivering new capabilities and outcomes）
- Integrated Object Storage（原生 S3 相容物件儲存，**Technology Preview**）
- Improved Scalability and Interoperability of CNS（25K PV/Supervisor、50K/vCenter、RWX PV、linked clone）
- Faster File Management Operations（vSAN File Services SMB/NFS metadata 最佳化）

**Secure and Cyber Resilient Storage**（Easily protect and secure your data）
- Secure End-to-End Encryption（vSAN storage cluster data-in-transit encryption）
- High Levels of Security while Driving Down Storage Costs（data-at-rest encryption + Global Dedup GA）
- Simplified Site Maintenance and Failure Recovery（stretched cluster site-wide maintenance mode）
- Protect Data on Other Storage Types using vSAN（VMFS/NFS/vSAN multi-source replication）
- Comprehensive Cyber Protection and Recovery without the Cloud（on-prem clean room）
- Protecting VMs at Scale with Confidence（vSAN Protection and Recovery 強化）

**Simplified Operations**（Making storage easier and more intuitive）
- Fully Automated Resilience Settings（Auto-RAID in vSAN）
- Intuitive and Simple Capacity Management（全新 "effective capacity" 檢視）
- Consume vSAN Storage Clusters Across Workload Domains（cross-vCenter storage cluster）
- Global Visibility and Insight for Storage（VCF Operations 儲存與資料保護檢視）

> **Technology Preview** 的功能（如原生 S3 物件儲存）在客戶版一定要標註 TP，不可講成 GA。

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

兩份底版都內含 **"Do Not Distribute This Presentation"** Broadcom 內部聲明頁（vSAN 版還多一頁 PowerPoint 警語）。

- 對外（客戶/VMUG/Explore）版本：**移除 speaker notes**，並改用可留存的 PDF（SRC 上有對外 PDF 版）。
- 內部 enablement：保留 disclaimer 頁與 speaker notes。
- 客製給特定客戶時，**先換掉封面標題/講者/日期**，刪掉不相關功能頁。
- **PowerPoint 警語頁不要刪**（內部版）：這份範本用了內嵌字型與精確排版，Google Slides 開會壞版。

---

## Speaker Notes Guidelines (中文)

- **每張 feature 頁**：1 句帶到「這功能解決客戶什麼痛點」，再講 2–3 個技術細節。
- **DEMO 頁**：寫 demo 環境前置條件（版本、需求），避免現場才發現不支援。
- **Upgrade Path 頁**：強調這是「最快取得 VCF 9.1 能力」的路徑（先升 Ops，再升 vCenter/ESX）。
- **AI/硬體頁 (AMD/NVIDIA)**：標註支援的 GPU/CPU 型號，提醒客戶查 HCL。
- **儲存頁**：帶到授權影響（vSAN 容量授權 / VCF 內含額度）與 HCL（ReadyNode、NVMe 型號）。
- 一律 **conclusion-first**、英文技術名詞 + 中文敘述。

---

## 產出流程 — 照官方美術版，又不燒 token

**核心原則：美術留在檔案裡，只讓文字進 context。**
一張官方內容頁的 XML 約 293,000 字元，純文字只有約 950 字元 —— 差 310 倍。
所以**複製整頁換字**，絕不用 python-pptx 從空白頁「照著色票規格重畫」（又貴又不像）。

### 標準四步

```bash
S=scripts/clone-slide.py

# 1. 先看範本有什麼（354 字元，取代讀 293K 的 XML）
python3 $S list TECH_TUESDAY_Whats_New_with_vSAN_in_VCF_9_1.pptx
python3 $S list ...pptx --slide 6          # 單頁的可填欄位

# 2. 砍到只剩要的骨架（順序照給的順序）
python3 $S keep ...pptx --slides 1,2,3,4,5 --out deck.pptx

# 3. 每張 feature 頁：複製一張「圖已經對」的頁，換文字
python3 $S clone deck.pptx --slide 5 --out deck.pptx \
  --title "客戶得到什麼好處" \
  --subtitle "功能名 / 一句技術描述" \
  --bullets "重點一|重點二|1:次階重點"

# 4. QA 看圖不看 XML
soffice --headless --convert-to pdf --outdir qa deck.pptx
pdftoppm -png -r 70 -f 4 -l 6 qa/deck.pdf qa/slide
```

### 配套檔

| 檔案 | 用途 |
|------|------|
| `references/layout-map.md` | 兩份範本全部版型的「名稱 → 檔案 → master → 幾何」對照，省掉開檔掃 100+ 個 layout |
| `scripts/clone-slide.py` | `list` / `clone` / `settext` / `keep` |
| `scripts/gen-layout-map.py` | 範本換版時重產上面那張表 |

### 其他既有規則

- **內容草稿與檔案生成分開**：先在對話確認所有 feature 頁文字，再一次生成 .pptx。
- 大型 deck（>20 頁）分多個對話產出，避免單次 token 爆量。
- **Front-load 需求**：一開始就講清楚要哪些 section、哪些 feature、要不要 DEMO 頁、對內或對外版本。
- 模板型 deck 用標準 chat + `vcf-*` skill，**不要用 Cowork**。
- **挑對頁再複製**：`clone` 不會改圖，所以要選一張示意圖本來就對的頁；
  拿壓縮示意圖的頁去講授權，文字對了圖也是錯的。
- `--bullets` **不吃 markdown**，`**粗體**` 會原樣印出星號。
