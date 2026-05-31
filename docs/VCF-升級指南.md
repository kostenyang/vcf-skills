# VMware Cloud Foundation 升級完整指南 (Deploy / Converge / Import / Upgrade)

> 本文件為可獨立閱讀之技術指南。所有版本號、路徑與前置條件均以本文「已查證事實」與文末「參考來源」為依據；任何未明確列出的細節，一律**以官方 Broadcom Release Notes 與 Interop / Interoperability Matrix 為唯一準則**。

---

## 目錄

1. [文件目的與適用範圍](#1-文件目的與適用範圍)
2. [四種落地方式總覽 (Deploy / Converge / Import / Upgrade)](#2-四種落地方式總覽-deploy--converge--import--upgrade)
3. [升級路徑 (Upgrade Paths)](#3-升級路徑-upgrade-paths)
4. [VCF 5.2 → 9.0 前置條件 (最關鍵章節)](#4-vcf-52--90-前置條件-最關鍵章節)
5. [標準升級順序 (Upgrade Sequence)](#5-標準升級順序-upgrade-sequence)
6. [風險管理與 Rollback 策略](#6-風險管理與-rollback-策略)
7. [Converge 流程要點](#7-converge-流程要點)
8. [Import 流程要點](#8-import-流程要點)
9. [9.0.x → 9.1 升級](#9-90x--91-升級)
10. [完整 Checklist](#10-完整-checklist)
11. [參考來源](#11-參考來源)

---

## 1. 文件目的與適用範圍

本指南說明如何將既有或全新環境導入 / 升級至 VMware Cloud Foundation (VCF)，涵蓋四種落地方式與多條升級路徑，並特別聚焦於**架構性的 VCF 5.x → 9.0 跨大版本升級**。

適用對象：負責 VCF / VVF 規劃、導入與升級的架構師與維運團隊。

核心原則：

- 一切以 **Broadcom Release Notes + Interop Matrix** 為唯一準則。
- 跨大版本 (例如 5.2 → 9.0) 屬於架構性升級，**務必先於測試環境完整演練**後再進入正式環境。
- 任何本文未涵蓋或不確定之細節，**以官方文件為準**。

---

## 2. 四種落地方式總覽 (Deploy / Converge / Import / Upgrade)

VCF 提供四種把環境帶入 VCF / VVF 管理的方式，依現有環境狀態選擇：

| 方式 | 適用情境 | 說明 |
|------|----------|------|
| **Deploy** | 綠地新建 (Greenfield) | 從零建立全新 VCF 環境。 |
| **Converge** | 既有 vSphere / vCenter + ESX | 將既有 vSphere 環境**原地轉換 (in-place convert)** 成 VCF / VVF。 |
| **Import** | 既有環境匯入 | 將既有環境**匯入 VCF 管理**；需求與 Converge 略有不同。 |
| **Upgrade** | 既有 VCF | 將既有 VCF 環境**往上升版**。 |

> Converge 與 Import 都針對「既有非 VCF 環境」，但兩者的前置需求不同，請依官方 deployment 文件 (見參考來源) 區分判斷適用哪一種。

---

## 3. 升級路徑 (Upgrade Paths)

下表整理本指南涵蓋的升級路徑。能否 skip-level (跳版) 升級，**務必先以 Interop Matrix 與 Release Notes 確認受支援**。

| 來源版本 | 目標版本 | 路徑特性 | 機制 / 重點 |
|----------|----------|----------|-------------|
| VCF 4.5.0+ | VCF 5.2.1 | 循序 (sequential) 或 skip-level | skip-level 須確認受支援。 |
| VCF 5.2 | VCF 5.2.1 | 同系列小幅升級 | 透過 **SDDC Manager LCM bundle** 升級。 |
| VCF 5.x | VCF 9.0 | **跨大版本 (架構性升級，本指南重點)** | 需完成多項前置 remediation，見第 4 章。 |
| VCF 9.0.x | VCF 9.1 | 同系列，較單純 | 見第 9 章。 |

要點：

- **VCF 4.5.0+ → 5.2.1**：可循序或 skip-level；採 skip-level 前必須確認該路徑受支援。
- **VCF 5.2 → 5.2.1**：屬同系列 LCM 升級，透過 SDDC Manager LCM bundle 完成。
- **VCF 5.x → 9.0**：跨大版本的**架構性升級**，是本文重點，前置條件最多 (第 4 章)。
- **VCF 9.0.x → 9.1**：同系列升級，相對單純。

---

## 4. VCF 5.2 → 9.0 前置條件 (最關鍵章節)

5.2 → 9.0 是架構性的跨大版本升級。**進入 ESX host 升級階段之前**，下列前置條件必須完成。任何版本門檻請以 Interop Matrix 與 Release Notes 為準。

### 4.1 前置條件清單

| # | 前置條件 | 細節 / 時機 |
|---|----------|-------------|
| 1 | **所有 ESX 叢集由 baseline 轉為 vLCM image** | 必須在 **ESX host 升級階段之前**完成。VCF 9 **不支援 baseline**，僅支援 vLCM image。 |
| 2 | **移除 Enhanced Linked Mode (ELM)** | 升級前須先解除 ELM。 |
| 3 | **DVS 升級至支援版本** | 將 Distributed Virtual Switch (DVS) 升到 9.0 支援的版本。 |
| 4 | **元件最低版本** | 依目標 patch 版本而異，見下方 4.2。 |
| 5 | **必要時先升至中間版本 (interim)** | 依現有版本，可能需先升到一個 interim 中間版本，再續升至 9.0。 |
| 6 | **硬體須在 VCF 9 / vSAN ESA HCL 上** | 硬體須列於 VCF 9 與 vSAN ESA 的 HCL (Hardware Compatibility List)。 |

### 4.2 元件最低版本 (依目標版本)

| 目標版本 | 元件版本需求 |
|----------|--------------|
| **轉換到 9.0.0** | 需 **ESX 先升到 9** 再進行轉換。 |
| **轉換到 9.0.1** | 需 **vCenter ≥ 8.0 U1a**、**NSX ≥ 4.1.0.2**、**ESX ≥ 8.0 U1a**。 |

> 上述為已查證之最低版本門檻。其餘元件 (例如 VCF Operations / Automation 等) 的版本相容性，**以官方 Interop Matrix 為準**。

### 4.3 為何要在 ESX host 升級「之前」完成 image 轉換

VCF 9 不再支援 baseline 模式，全面採用 vLCM image。若 ESX host 在升級階段時叢集仍為 baseline 管理，將無法正確進行 image-based 的生命週期管理，因此 **baseline → vLCM image 的轉換必須先於 ESX host 升級階段**完成。

---

## 5. 標準升級順序 (Upgrade Sequence)

無論路徑為何，建議遵循下列大階段順序。管理域內部的元件升級具有明確先後關係。

```
規劃盤點
  → 前置 remediation (image / ELM / DVS / interim)
    → 備份
      → 管理域 (Management Domain)
          SDDC Manager → vCenter → NSX → ESX
        → 工作負載域 (Workload Domains)
          → 營運 / 自動化 (VCF Operations / Automation)
            → 驗證收尾
```

### 5.1 各階段說明

| 階段 | 動作 |
|------|------|
| 1. 規劃盤點 | 盤點現有版本、叢集、硬體、ELM、DVS、HCL 狀態。 |
| 2. 前置 remediation | 完成 baseline→image 轉換、移除 ELM、DVS 升版、必要的 interim 升級。 |
| 3. 備份 | 對相關元件進行備份 (見第 6 章)。 |
| 4. 管理域升級 | 依序升級 **SDDC Manager → vCenter → NSX → ESX**。 |
| 5. 工作負載域升級 | 升級各 Workload Domain。 |
| 6. 營運 / 自動化 | 升級 VCF Operations / Automation 相關元件。 |
| 7. 驗證收尾 | 完整功能與健康度驗證。 |

> 管理域內部順序為固定的 **SDDC Manager → vCenter → NSX → ESX**，請勿調換。

---

## 6. 風險管理與 Rollback 策略

| 項目 | 做法 |
|------|------|
| 快照 / 備份 | **每個階段都建立快照 / 備份**。 |
| Rollback | 針對每個階段事先**定義明確的 rollback 程序**。 |
| skip-level | 採用 skip-level 升級前，**確認該路徑受支援** (Interop Matrix / Release Notes)。 |
| 並行升級規模 | **9.1 並行升級可達 256 clusters**。 |
| 架構性升級 | **5.2 → 9.0 為架構性升級，務必先在測試環境演練**後再上正式環境。 |

---

## 7. Converge 流程要點

Converge 是將既有 vSphere / vCenter + ESX 環境**原地轉換**為 VCF / VVF。

要點：

- 適用於既有 vSphere 環境，避免綠地重建。
- 轉換到 **9.0.0** 時，需先把 **ESX 升到 9** 再轉換。
- 轉換到 **9.0.1** 時，元件須符合 **vCenter ≥ 8.0 U1a、NSX ≥ 4.1.0.2、ESX ≥ 8.0 U1a**。
- 前置 remediation (image / ELM / DVS) 同樣適用，請對照第 4 章。
- 詳細操作步驟**以官方 "How to converge a vSphere environment to VCF 9.0" 文件為準** (見參考來源)。

---

## 8. Import 流程要點

Import 是將既有環境**匯入 VCF 管理**。

要點：

- 與 Converge 同屬「既有非 VCF 環境帶入 VCF」的途徑，但**前置需求與 Converge 略有不同**。
- 選擇 Converge 或 Import，須依環境現況與官方 deployment 文件的判斷準則決定。
- 具體前置需求差異與支援矩陣，**以官方 deployment 文件為準** (見參考來源)。

---

## 9. 9.0.x → 9.1 升級

| 項目 | 說明 |
|------|------|
| 路徑特性 | 同系列升級，相較跨大版本**較為單純**。 |
| 並行規模 | 並行升級可達 **256 clusters**。 |
| 順序 | 仍遵循第 5 章的標準升級順序。 |
| 前置條件 | 以 9.1 Release Notes 與 Interop Matrix 為準。 |

---

## 10. 完整 Checklist

### 10.1 規劃 / 盤點階段

- [ ] 確認現有 VCF / vSphere 版本與目標版本。
- [ ] 確認升級路徑是否受支援 (循序 vs skip-level)。
- [ ] 盤點所有 ESX 叢集的管理模式 (baseline vs vLCM image)。
- [ ] 盤點 Enhanced Linked Mode (ELM) 使用狀況。
- [ ] 盤點 DVS 版本。
- [ ] 確認硬體是否在 **VCF 9 / vSAN ESA HCL** 上。
- [ ] 確認是否需要先升至 interim 中間版本。

### 10.2 前置 Remediation 階段 (5.2 → 9.0)

- [ ] 將所有 ESX 叢集由 baseline 轉換為 **vLCM image**（須在 ESX host 升級階段之前完成）。
- [ ] 移除 **Enhanced Linked Mode (ELM)**。
- [ ] 將 **DVS** 升級至支援版本。
- [ ] 確認元件最低版本：
  - [ ] 轉換到 9.0.0：ESX 已先升到 9。
  - [ ] 轉換到 9.0.1：vCenter ≥ 8.0 U1a、NSX ≥ 4.1.0.2、ESX ≥ 8.0 U1a。
- [ ] 完成必要的 interim 中間版本升級。

### 10.3 備份階段

- [ ] 對相關元件建立備份。
- [ ] 為每個階段建立快照。
- [ ] 為每個階段定義 rollback 程序。

### 10.4 執行階段

- [ ] 管理域：**SDDC Manager → vCenter → NSX → ESX** 依序升級。
- [ ] 升級各 **Workload Domain**。
- [ ] 升級 **VCF Operations / Automation**。
- [ ] (9.1) 確認並行升級叢集數未超過 **256 clusters**。

### 10.5 驗證收尾階段

- [ ] 驗證所有元件版本符合目標。
- [ ] 驗證叢集健康度與工作負載運行狀態。
- [ ] 對照 Interop Matrix 確認最終相容性。
- [ ] 確認測試環境演練結果與正式環境一致 (跨大版本升級)。

---

## 11. 參考來源

- Overview of Deploy, Converge, and Upgrade (VCF 9.0 and later)
  https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/deployment/overview-of-deploy--converge--and-upgrade.html
- How to Upgrade to VMware Cloud Foundation 9.0
  https://blogs.vmware.com/cloud-foundation/2025/09/25/how-to-upgrade-to-vmware-cloud-foundation-9-0/
- Upgrading VMware Cloud Foundation 5.2 to 9.0 – The Top 10 Questions Answered
  https://blogs.vmware.com/cloud-foundation/2025/12/18/upgrading-vmware-cloud-foundation-5-2-to-9-0-the-top-10-questions-answered/
- How to Converge a VMware vSphere Environment to VMware Cloud Foundation 9.0
  https://blogs.vmware.com/cloud-foundation/2026/02/05/how-to-converge-a-vmware-vsphere-environment-to-vmware-cloud-foundation-9-0/

> 最終準則：**Broadcom Release Notes + Interop Matrix**。本文件未明確涵蓋之版本號、日期或數字，一律以官方文件為準。
