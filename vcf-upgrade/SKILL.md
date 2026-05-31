---
name: vcf-upgrade
description: >-
  VMware Cloud Foundation 升級專門知識 skill。涵蓋 VCF 升級路徑與三大落地方式：
  Deploy / Converge / Import；VCF 5.2 → 9.0 跨大版本升級、9.0.x → 9.1 同系列升級、
  5.2 → 5.2.1 / skip-level、vSphere 環境轉換 (Converge) 進 VCF 9、
  前置條件 (vLCM image 化、移除 ELM、DVS 修正、元件最低版本)、升級順序與回退。
  當使用者詢問 VCF 升級、upgrade、升級路徑、升級規劃、Converge、Import、
  5.2 升 9.0、9.0 升 9.1、跳版升級、升級前置條件、或升級簡報 / runbook 時觸發。
  也適用於 升級路徑、升級規劃、轉換納管 等中文需求。
---

# VMware Cloud Foundation 升級

本 skill 統整 VCF 各版本的升級與轉換路徑、前置條件、順序與風險，
是規劃 VCF 升級專案的主要參考。產品版本細節請搭配 `vcf-9`、`vcf-521` skill。

## 使用時機

- 規劃 VCF 升級專案（5.2 → 9.0、9.0 → 9.1、5.2 → 5.2.1）
- 把既有 vSphere / vCenter 環境轉換 (Converge) 或匯入 (Import) 進 VCF 9
- 盤點升級前置條件與相容性
- 設計升級順序、維護窗、回退方案
- 撰寫升級 runbook / 簡報

## 三種落地方式 (VCF 9)

| 方式 | 說明 | 適用 |
|------|------|------|
| **Deploy** | 全新部署 VCF 9 | 綠地新建 |
| **Converge** | 將既有 vSphere/vCenter + ESX 原地轉換成 VCF/VVF | 既有 vSphere 想原地納管 |
| **Import** | 把既有環境匯入 VCF 管理（要求略不同於 Converge） | 既有環境納管 |
| **Upgrade** | 既有 VCF 版本往上升 | 已是 VCF 的環境 |

## 升級路徑速查

| 來源 | 目標 | 性質 | 重點 |
|------|------|------|------|
| VCF 4.5.0+ | VCF 5.2.1 | 同大版本 / skip-level | 循序或跳版皆可 |
| VCF 5.2 | VCF 5.2.1 | 小版本 | SDDC Manager LCM bundle |
| **VCF 5.x** | **VCF 9.0** | **跨大版本（重點）** | 大量前置條件，見下 |
| VCF 9.0.x | VCF 9.1 | 同系列 | 較單純，仍須對 BOM/interop |

## VCF 5.2 → 9.0 前置條件 (最關鍵)

> 這是整個升級專案最容易踩雷的地方，務必逐項確認。

1. **vLCM image 化**：所有 ESX 叢集必須從 **baseline → vLCM image**，
   baseline 在 VCF 9 不再支援。**須在 ESX host 升級階段之前完成**。
2. **移除 Enhanced Linked Mode (ELM)**：轉換前必須先移除 ELM。
3. **DVS 版本修正**：Distributed Virtual Switch 需升到支援版本。
4. **元件最低版本**（依目標 9.0.x 不同）：
   - 轉換到 **9.0.0**：ESX 必須先升到 **9** 再轉換。
   - 轉換到 **9.0.1**：vCenter ≥ **8.0 U1a**、NSX ≥ **4.1.0.2**，
     ESX 可在 **8.0 U1a 以上**。
5. **interim 中間步驟**：依現有 vSphere / NSX / VCF Operations 版本，
   可能需要先升到某些中間版本再進 9.0。
6. **硬體相容性**：確認在 VCF 9 / vSAN ESA HCL。

## 升級順序 (一般原則)

1. 規劃 + 盤點（版本、HCL、相容性、容量）。
2. 完成前置 remediation（image 化、移除 ELM、DVS、interim 升級）。
3. 備份 SDDC Manager / 管理元件 / 設定。
4. 升管理域（SDDC Manager → vCenter → NSX → ESX），再升工作負載域。
5. 升級營運/自動化（VCF Operations / Automation）。
6. 驗證 + 收尾。

## 風險與回退

- 每階段前做快照 / 備份；規劃 cutover 與 rollback。
- 跳版升級 (skip-level) 雖省時間，仍須確認該路徑受支援。
- 確認維護窗足夠（大規模環境的並行升級能力：9.1 達 256 clusters）。

詳細內容見 `references/upgrade-5.2-to-9.0.md`。

## 重要提醒

- 升級牽涉多元件 BOM，請以 **Broadcom Release Notes + Interop Matrix** 為唯一準則。
- 5.2 → 9.0 是「架構性升級」，非單純版本號跳動，務必充分測試。

## 權威來源
- Overview of Deploy, Converge, and Upgrade: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/deployment/overview-of-deploy--converge--and-upgrade.html
- How to Upgrade to VCF 9.0: https://blogs.vmware.com/cloud-foundation/2025/09/25/how-to-upgrade-to-vmware-cloud-foundation-9-0/
- Upgrading VCF 5.2 to 9.0 — Top 10 Questions: https://blogs.vmware.com/cloud-foundation/2025/12/18/upgrading-vmware-cloud-foundation-5-2-to-9-0-the-top-10-questions-answered/
- Converging vSphere to VCF 9.0: https://blogs.vmware.com/cloud-foundation/2026/02/05/how-to-converge-a-vmware-vsphere-environment-to-vmware-cloud-foundation-9-0/
- Navigating the Pathways to VCF 9.1 (ebook): https://www.vmware.com/docs/navigating-the-pathways-to-vmware-cloud-foundation-9-1-ebook
