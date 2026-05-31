# VMware Cloud Foundation 5.2.1 完整技術指南

> 本文件為可獨立閱讀之技術參考文件，內容基於 Broadcom 官方公開資訊整理。凡涉及精確版本號、相容性矩陣、授權細節與升級路徑的最終判定，一律以官方文件為準。

---

## 目錄

1. [文件總覽](#1-文件總覽)
2. [VCF 5.2.1 在版本演進中的定位](#2-vcf-521-在版本演進中的定位)
3. [整體架構](#3-整體架構)
4. [核心元件](#4-核心元件)
5. [Cluster 生命週期管理：vLCM baseline vs. image](#5-cluster-生命週期管理vlcm-baseline-vs-image)
6. [VCF 5.2.1 新功能詳解](#6-vcf-521-新功能詳解)
7. [Lifecycle Management 與升級彈性](#7-lifecycle-management-與升級彈性)
8. [獨立 SDDC Manager 升級](#8-獨立-sddc-manager-升級)
9. [作為 VCF 9.0 升級來源的前置準備](#9-作為-vcf-90-升級來源的前置準備)
10. [Checklist 清單](#10-checklist-清單)
11. [常見問題 (FAQ)](#11-常見問題-faq)
12. [參考來源](#12-參考來源)

---

## 1. 文件總覽

VMware Cloud Foundation (VCF) 5.2.1 是 VCF 9 推出之前，企業環境中廣泛部署的 5.x 版本。它採用傳統的 **SDDC Manager + Workload Domain** 架構，將 compute、storage、network 與管理層整合為一套以軟體定義資料中心 (Software-Defined Data Center, SDDC) 為核心的私有雲平台。

本文件的目的：

- 說明 VCF 5.2.1 的架構與核心元件。
- 整理 5.2.1 版本相對於先前版本的新功能。
- 提供 lifecycle management 與升級彈性的概念說明。
- 為計畫升級到 VCF 9.0 的環境提供前置準備指引。

> **適用對象**：VMware/Broadcom 架構師、雲端平台工程師、資料中心維運團隊。

---

## 2. VCF 5.2.1 在版本演進中的定位

VCF 5.2.1 具有以下定位特性：

- 屬於 VCF 9 之前**廣泛部署**的 5.x 版本。
- 沿用傳統的 **SDDC Manager + Workload Domain** 架構。
- 常被當作**升級到 VCF 9.0 的來源版本** (source version)。

換言之，許多既有環境會先收斂到 VCF 5.2.1 這個穩定基準，再規劃往 VCF 9.0 / 9.0.1 的後續轉換。這使得 5.2.1 同時扮演「穩定營運版本」與「升級跳板」兩種角色。

| 角色 | 說明 |
|------|------|
| 穩定營運版本 | 傳統 SDDC Manager + Workload Domain，5.x 系列中廣泛部署 |
| 升級跳板 | 作為轉換到 VCF 9.0 的來源版本，承接前置準備工作 |

---

## 3. 整體架構

VCF 5.2.1 以 **SDDC Manager** 為自動化與生命週期管理的核心，管理一個 Management Domain 與多個 VI Workload Domain。

### 3.1 架構分層

```
┌─────────────────────────────────────────────────────────┐
│                      SDDC Manager                         │
│        (LCM 生命週期管理 + 自動化 orchestration)           │
└─────────────────────────────────────────────────────────┘
            │ 管理
            ▼
┌─────────────────────────┐   ┌──────────────────────────┐
│   Management Domain      │   │   VI Workload Domain (多個) │
│  - vCenter               │   │  - 業務工作負載 VM         │
│  - NSX                   │   │  - 各自的 vCenter/叢集     │
│  - SDDC Manager          │   │  - Cluster: baseline      │
│  - 管理用 VM             │   │            或 image       │
└─────────────────────────┘   └──────────────────────────┘
```

### 3.2 各層職責

| 層級 | 內容 | 職責 |
|------|------|------|
| **SDDC Manager** | LCM + 自動化 | 統一管理 Management Domain 與所有 VI Workload Domain，負責部署、生命週期管理與自動化作業 |
| **Management Domain** | vCenter、NSX、SDDC Manager、管理用 VM | 承載整個 VCF 平台的管理元件與管理 VM |
| **VI Workload Domain** | 業務工作負載 | 承載實際的業務 VM，可有多個，彼此邏輯隔離 |

### 3.3 Cluster 生命週期模式

在 VCF 5.2.1 中，每個 Cluster 可以採用兩種生命週期管理方式之一：

- **vLCM baseline**：以 baseline 方式管理叢集。
- **vLCM image**：以 image 方式管理叢集。

> 詳細差異與混用規則見[第 5 章](#5-cluster-生命週期管理vlcm-baseline-vs-image)。

---

## 4. 核心元件

VCF 5.2.1 將下列虛擬化堆疊元件整合在一起，由 SDDC Manager 統一進行 lifecycle management。

| 元件類別 | 版本系列 | 說明 |
|----------|----------|------|
| Hypervisor / Compute | **vSphere 8.x** | 提供 compute 虛擬化基礎 |
| Storage | **vSAN 8.x** | 提供軟體定義儲存 |
| Network | **NSX 4.x** | 提供軟體定義網路與安全 |
| 管理 / 自動化 | SDDC Manager | 負責 LCM 與自動化 orchestration |

> **註**：上表所列為元件版本「系列」。確切的元件版本號、BOM (Bill of Materials) 與相容性組合，請以 VCF 5.2.1 官方 Release Notes 與相容性矩陣為準。

---

## 5. Cluster 生命週期管理：vLCM baseline vs. image

vSphere Lifecycle Manager (vLCM) 提供兩種叢集管理模型。理解兩者的差異，以及 5.2.1 對混用的支援，是規劃升級與維運的關鍵。

| 項目 | vLCM baseline | vLCM image |
|------|---------------|------------|
| 管理模型 | 以 baseline 管理 | 以單一 desired-state image 管理 |
| 角色定位 | 傳統模式 | VCF 9.0 唯一支援模式 |
| 在 5.2.1 的支援 | 支援 | 支援 |
| NSX in-place 升級 | 支援 (見第 6 章) | 以官方文件為準 |

### 5.1 5.2.1 對混用的支援

VCF 5.2.1 新增了一項重要的彈性：**在同一個 Workload Domain 內，可以同時混用 vLCM baseline 與 image-based 叢集**。

這項能力的意義在於：

- 不必一次把整個 Workload Domain 內所有叢集都轉換成同一種模型。
- 可以在同一個 Workload Domain 中，逐步把 baseline 叢集轉換成 image-based 叢集。
- 為日後升級到 VCF 9.0 (僅支援 image) 預留了平滑的過渡路徑。

---

## 6. VCF 5.2.1 新功能詳解

以下為 VCF 5.2.1 相對於先前版本所引入的主要新功能。

### 6.1 同一 Workload Domain 內混用 baseline 與 image 叢集

如[第 5 章](#5-cluster-生命週期管理vlcm-baseline-vs-image)所述，5.2.1 允許在**同一個 Workload Domain 內混用 vLCM baseline 叢集與 image-based 叢集**。這提供了叢集生命週期模型轉換的彈性，無需整個 Workload Domain 同步切換。

### 6.2 NSX in-place 升級

VCF 5.2.1 對 **vLCM baseline 叢集**支援 **NSX in-place 升級**。

關鍵特性：

- 適用對象：**vLCM baseline 叢集**。
- 核心優勢：升級 NSX 時，**不需要把 host 進入 maintenance mode**。

這對於降低升級期間的工作負載中斷與遷移壓力有實際幫助，特別是在 host 數量較多或工作負載難以大量 vMotion 的環境中。

> image-based 叢集的 NSX 升級行為，以官方文件為準。

### 6.3 vSAN TiB 容量授權 (License Now)

VCF 5.2.1 引入了 **vSAN TiB 容量授權**的方式：

- 可在 **SDDC Manager UI** 中，以**每 TiB 容量**的方式套用 vSAN add-on 授權。
- 對應的 UI 操作流程名稱為 **License Now**。

這讓 vSAN 授權的套用以實際容量 (TiB) 為單位進行管理。具體授權條款、計價與適用範圍，以官方授權文件為準。

### 6.4 憑證與密碼管理整合進 vSphere Client

VCF 5.2.1 將**憑證與密碼管理整合進 vSphere Client 的 Administration 區**，涵蓋：

- 憑證 (certificate) 管理。
- 整合式 CA (integrated CA)。
- 系統使用者密碼 (system user password) 管理。

| 管理項目 | 整合位置 |
|----------|----------|
| 憑證 (Certificate) | vSphere Client → Administration |
| 整合式 CA (Integrated CA) | vSphere Client → Administration |
| 系統使用者密碼 (System user password) | vSphere Client → Administration |

這使得相關的安全性與身分管理作業可在 vSphere Client 內統一進行。

### 6.5 獨立 SDDC Manager 升級

VCF 5.2.1 支援**獨立升級 SDDC Manager**。詳見[第 8 章](#8-獨立-sddc-manager-升級)。

### 6.6 升級彈性 (循序與跳版)

VCF 5.2.1 支援從較舊版本進行**循序 (sequential)** 或**跳版 (skip-level)** 升級。詳見[第 7 章](#7-lifecycle-management-與升級彈性)。

---

## 7. Lifecycle Management 與升級彈性

SDDC Manager 是 VCF lifecycle management 的核心，負責協調整個平台的版本升級。

### 7.1 升級來源版本範圍

VCF 5.2.1 支援從 **VCF 4.5.0 或更新版本**升級而來：

- 可採用**循序 (sequential) 升級**：逐版升級到 5.2.1。
- 可採用**跳版 (skip-level) 升級**：直接跨越中間版本升級到 5.2.1。

| 升級方式 | 來源版本 | 目標版本 | 說明 |
|----------|----------|----------|------|
| 循序升級 (sequential) | VCF 4.5.0 或更新版本 | VCF 5.2.1 | 逐版本依序升級 |
| 跳版升級 (skip-level) | VCF 4.5.0 或更新版本 | VCF 5.2.1 | 跨越中間版本直接升級 |

> 具體支援的來源版本、路徑與每個路徑的前置條件，以官方 lifecycle management 文件與相容性矩陣為準。

---

## 8. 獨立 SDDC Manager 升級

VCF 5.2.1 提供了一項重要的維運彈性：**SDDC Manager 可獨立升級，而不必同步升級整個 VCF BOM。**

### 8.1 概念說明

- 當 SDDC Manager 升級到 **5.2 以上**之後，便可以**單獨升級 SDDC Manager**。
- 透過單獨升級，可取得**新功能**與**安全修補 (security patch)**。
- 不需要升級整個 VCF BOM (Bill of Materials)，亦即不必同步升級 vSphere / vSAN / NSX 等所有元件。

### 8.2 價值

| 面向 | 傳統做法 | 獨立 SDDC Manager 升級 |
|------|----------|------------------------|
| 升級範圍 | 整個 VCF BOM 一起升級 | 僅升級 SDDC Manager |
| 取得安全修補的速度 | 受制於整體 BOM 升級節奏 | 可較快取得 SDDC Manager 安全修補 |
| 取得新功能 | 需整體升級 | 可單獨取得 SDDC Manager 新功能 |

> 此能力的前提是 SDDC Manager 已升至 5.2 以上。詳細操作步驟與限制，請參閱官方文件「Upgrade SDDC Manager Without Upgrading VCF Lifecycle」(見[參考來源](#12-參考來源))。

---

## 9. 作為 VCF 9.0 升級來源的前置準備

VCF 5.2.1 常被用作升級到 VCF 9.0 的來源版本。在執行轉換之前，需要完成下列前置準備。

### 9.1 前置準備項目

| 前置項目 | 內容 | 原因 |
|----------|------|------|
| 叢集模型轉換 | 所有叢集 **baseline → vLCM image** | VCF 9 **不支援 baseline** |
| 移除 ELM | 移除 ELM (Enhanced Linked Mode) | 為轉換做準備 |
| 修正 DVS | 修正 DVS (Distributed Virtual Switch) | 為轉換做準備 |

### 9.2 轉換到 9.0.1 的元件版本前置條件

若要轉換到 **VCF 9.0.1**，需滿足下列元件版本下限：

| 元件 | 版本要求 |
|------|----------|
| vCenter | **>= 8.0 U1a** |
| NSX | **>= 4.1.0.2** |

> 上述為轉換到 9.0.1 的明確版本下限。其餘元件的最低版本要求、完整相容性組合與詳細操作流程，以官方升級文件為準。

### 9.3 前置準備邏輯關係

```
VCF 5.2.1 (來源)
   │
   ├─ 步驟 1：所有叢集 baseline → vLCM image  (因 VCF 9 不支援 baseline)
   ├─ 步驟 2：移除 ELM
   ├─ 步驟 3：修正 DVS
   │
   ├─ 元件下限 (轉換到 9.0.1)：
   │     - vCenter >= 8.0 U1a
   │     - NSX     >= 4.1.0.2
   ▼
VCF 9.0 / 9.0.1 (目標)
```

---

## 10. Checklist 清單

### 10.1 架構理解 Checklist

- [ ] 已確認 SDDC Manager 負責 LCM 與自動化，並管理 Management Domain 與多個 VI Workload Domain。
- [ ] 已確認 Management Domain 承載 vCenter / NSX / SDDC Manager 與管理 VM。
- [ ] 已確認核心元件為 vSphere 8.x / vSAN 8.x / NSX 4.x (確切版本以官方 BOM 為準)。
- [ ] 已盤點各叢集採用 vLCM baseline 或 image 模型。

### 10.2 新功能採用 Checklist

- [ ] 評估是否需要在同一 Workload Domain 內混用 baseline 與 image 叢集。
- [ ] 確認 NSX in-place 升級適用範圍 (vLCM baseline 叢集，升級時 host 不需進入 maintenance mode)。
- [ ] 評估是否採用 vSAN TiB 容量授權 (透過 SDDC Manager UI 的 License Now，以每 TiB 套用 vSAN add-on)。
- [ ] 確認憑證 / 整合式 CA / 系統使用者密碼管理已可在 vSphere Client 的 Administration 區操作。

### 10.3 升級規劃 Checklist

- [ ] 確認來源版本為 VCF 4.5.0 或更新版本。
- [ ] 決定採用循序 (sequential) 或跳版 (skip-level) 升級到 5.2.1。
- [ ] 評估是否使用獨立 SDDC Manager 升級 (前提：SDDC Manager 已在 5.2 以上)。
- [ ] 對照官方相容性矩陣確認升級路徑與前置條件。

### 10.4 VCF 9.0 升級前置 Checklist

- [ ] 所有叢集已從 baseline 轉換為 vLCM image (VCF 9 不支援 baseline)。
- [ ] 已移除 ELM (Enhanced Linked Mode)。
- [ ] 已修正 DVS。
- [ ] 轉換到 9.0.1 前，vCenter 版本 >= 8.0 U1a。
- [ ] 轉換到 9.0.1 前，NSX 版本 >= 4.1.0.2。
- [ ] 其餘元件最低版本與完整路徑已對照官方升級文件確認。

---

## 11. 常見問題 (FAQ)

**Q1. VCF 5.2.1 的核心架構是什麼？**
A. 傳統的 SDDC Manager + Workload Domain 架構。SDDC Manager 負責 LCM 與自動化，管理一個 Management Domain 與多個 VI Workload Domain。

**Q2. 同一個 Workload Domain 內可以同時有 baseline 與 image 叢集嗎？**
A. 可以。這是 VCF 5.2.1 的新功能之一，允許在同一 Workload Domain 內混用 vLCM baseline 與 image-based 叢集。

**Q3. NSX in-place 升級時 host 需要進入 maintenance mode 嗎？**
A. 對 vLCM baseline 叢集而言，VCF 5.2.1 的 NSX in-place 升級在升級時**不需要**把 host 進入 maintenance mode。

**Q4. 一定要升級整個 VCF BOM 才能修補 SDDC Manager 嗎？**
A. 不一定。SDDC Manager 升到 5.2 以上後，可單獨升級以取得新功能與安全修補，不必升級整個 VCF BOM。

**Q5. 從哪些版本可以升級到 5.2.1？**
A. 可從 VCF 4.5.0 或更新版本，以循序或跳版 (skip-level) 方式升級到 5.2.1。具體路徑以官方文件為準。

**Q6. 升級到 VCF 9.0 之前要先做什麼？**
A. 將所有叢集從 baseline 轉為 vLCM image (VCF 9 不支援 baseline)、移除 ELM、修正 DVS。轉換到 9.0.1 還需 vCenter >= 8.0 U1a、NSX >= 4.1.0.2。

**Q7. vSAN TiB 容量授權怎麼套用？**
A. 在 SDDC Manager UI 中透過 License Now，以每 TiB 容量套用 vSAN add-on 授權。

---

## 12. 參考來源

- VMware Cloud Foundation 5.2.1 Release Notes
  https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-521-release-notes.html

- Upgrade SDDC Manager Without Upgrading VCF Lifecycle
  https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vmware-cloud-foundation-lifecycle-management/upgrade-sddc-manager-without-upgrading-vcf-lifecycle.html

---

> **免責聲明**：本文件為技術整理參考，凡涉及精確版本號、相容性矩陣、授權條款、升級路徑與操作步驟的最終判定，請一律以 Broadcom 官方 TechDocs 文件為準。
