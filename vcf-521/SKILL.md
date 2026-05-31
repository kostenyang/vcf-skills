---
name: vcf-521
description: >-
  VMware Cloud Foundation 5.2.1 專門知識 skill。涵蓋 VCF 5.2.1 的新功能、
  SDDC Manager、Workload Domain、vLCM baseline 與 image-based 混用、
  NSX in-place 升級、vSAN TiB 容量授權、憑證/密碼管理整合進 vSphere Client、
  獨立 SDDC Manager 升級 (不升整個 BOM)、循序與跳版升級 (skip-level)。
  當使用者詢問 VCF 5.2.1、VCF 5.2、SDDC Manager 5.2、Workload Domain 設計、
  vLCM baseline vs image、VCF 5.x 維運、或 VCF 5.2.1 相關規劃/升級/簡報時觸發。
  注意：5.2.1 是 VCF 9 之前的主流 5.x 版本，常作為升級到 9.0 的來源版本。
---

# VMware Cloud Foundation 5.2.1

VCF 5.2.1 是 VCF 9 之前廣泛部署的 5.x 版本，採傳統 SDDC Manager + Workload Domain
架構。本 skill 用來回答 5.2.1 的架構、新功能與維運；它也常是「升級到 VCF 9.0」
的來源版本。

## 使用時機

- 維運 / 規劃既有 VCF 5.2.x 環境
- VCF 5.2.1 新功能與 5.2 → 5.2.1 升級評估
- Workload Domain / SDDC Manager 設計
- vLCM baseline 與 image-based 混用情境
- 作為升級到 VCF 9.0 的「來源版本」盤點

> 5.2 → 9.0 的跨大版本升級流程請用 `vcf-upgrade` skill；VCF 9 架構用 `vcf-9` skill。

## VCF 5.2.1 架構重點

```
SDDC Manager (LCM + 自動化大腦)
├── Management Domain   ← 跑 vCenter / NSX / SDDC Manager / 管理元件
└── VI Workload Domain  ← 跑業務工作負載 (可多個)
    └── Cluster (vLCM baseline 或 image)
```

- **SDDC Manager**：負責 bring-up、Workload Domain 生命週期、自動化與 LCM。
- **Workload Domain**：管理域 + 一或多個 VI 工作負載域。
- 元件：vSphere 8.x / vSAN 8.x / NSX 4.x（依 5.2.1 BOM）。

## 5.2.1 主要新功能

- **同一 Workload Domain 內混用 vLCM baseline 與 image-based 叢集**：
  可在同一域同時部署 / 升級 baseline 叢集與 image 叢集。
- **NSX in-place 升級**：對使用 vLCM baseline 的叢集支援 in-place 升級，
  **升級時不需把 host 進入 maintenance mode**。
- **vSAN TiB 容量授權 (License Now)**：可在 SDDC Manager UI 以「每 TiB 容量」
  套用 vSAN add-on 授權，擴充 workload domain / cluster 儲存容量。
- **憑證與密碼管理整合進 vSphere Client**：SDDC Manager 的憑證、整合式 CA、
  系統使用者密碼管理，現可從 vSphere Client 的 Administration 區操作。
- **獨立 SDDC Manager 升級**：SDDC Manager 升到 5.2 以上後，可單獨取得
  SDDC Manager 的新功能與安全修補，**不必升整個 VCF BOM**。
- **升級彈性**：可從 VCF 4.5.0 或更新版本，做**循序或跳版 (skip-level)** 升級到 5.2.1。

詳細內容見 `references/vcf-5.2.1.md`。

## 作為升級來源的重要性

- VCF 9.0 的主要升級來源是 **VCF 5.x**。
- 在升到 9.0 前，5.2.1 環境須完成：所有叢集轉成 **vLCM image**（baseline 在 9
  不再支援）、移除 **ELM**、修正 **DVS 版本**等。
- 來源端 vCenter / NSX 版本需符合 9.0 Converge/Import 的最低版本要求。

## 重要提醒

- 5.2.1 仍是 baseline 與 image 可混用的版本；VCF 9 則僅支援 image。
- 版本與相容性以 Broadcom TechDocs / Release Notes 為準。

## 權威來源
- VCF 5.2.1 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-521-release-notes.html
- 獨立 SDDC Manager 升級: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vmware-cloud-foundation-lifecycle-management/upgrade-sddc-manager-without-upgrading-vcf-lifecycle.html
- VCF 5.2.1 on Dell VxRail Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-521-on-dell-vxrail-release-notes.html
