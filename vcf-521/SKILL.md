---
name: vcf-521
description: |
  VMware Cloud Foundation 5.2.1 專門知識 skill。涵蓋 VCF 5.2.1 的 BOM 元件版本 (SDDC Manager / vCenter 8.0 U3c / ESXi 8.0 U3b / NSX 4.2.1 / vSAN Witness 8.0 U3 / Aria Suite Lifecycle 8.18)、新功能 (vCenter Reduced Downtime Upgrade RDU、NSX in-place 升級、vLCM baseline 與 image 同域混用、vSAN TiB 容量授權 License Now、Private AI Foundation 與 DSM 整合、憑證/密碼管理整合進 vSphere Client、VPC/CCI 自助服務、VCF Import Tool)、循序與跳版 (skip-level) 升級路徑 (從 VCF 4.5+)、以及維運注意事項 (Depot 驗證變更 KB 390098、SSH 預設關閉 KB 86230、棄用事項)。當使用者詢問 VCF 5.2.1、VCF 5.2、SDDC Manager 5.2、Workload Domain 設計、vLCM baseline vs image、baseline→image 轉換 (5.2.2)、VCF 5.2.x BOM/build number、5.2.x 維運/升級規劃、或作為升級到 VCF 9.x 的來源版本盤點時觸發。也適用於 VCF 5.2.1 簡報、POC、相容性比對需求。注意：5.2.1 屬「VCF 5.2 and earlier」分支，與新一代 VCF 9.x 為不同產品線；常作為升級到 9.x 的來源版本。
---

# VMware Cloud Foundation 5.2.1

VCF 5.2.1 是 VMware Cloud Foundation 5.2 系列的第一個更新版（由 Broadcom 發行，
GA 2024-10-09，Build 24307856），採傳統 SDDC Manager + Workload Domain 架構。
本 skill 用來回答 5.2.1 的 BOM、架構、新功能與維運；它也常是「升級到 VCF 9.x」
的來源版本。

> 注意：5.2.x 屬「VCF 5.2 and earlier」分支；新一代 VCF 9.x（9.0 / 9.1）為不同產品線。
> 確切版號、build number 與相容性一律以 Broadcom TechDocs Release Notes 為準。

## 使用時機

- 維運 / 規劃既有 VCF 5.2.x 環境
- 查 VCF 5.2.1 BOM 元件版本與 build number
- VCF 5.2.1 新功能與 5.2 → 5.2.1 升級評估
- Workload Domain / SDDC Manager 設計
- vLCM baseline 與 image 混用情境，以及 baseline→image 轉換規劃
- 循序 (sequential) / 跳版 (skip-level) 升級路徑評估
- 作為升級到 VCF 9.x 的「來源版本」盤點
- Depot 下載失敗、SSH 預設關閉等維運疑難排解

> 5.2.x → 9.x 的跨大版本升級流程請用 `vcf-upgrade` skill；VCF 9 架構用 `vcf-9` skill；
> 製作簡報用對應的 `vcf-*-ppt` / 產業 skill。

## 核心重點

```
SDDC Manager (LCM + 自動化大腦)
├── Management Domain   ← 跑 vCenter / NSX / SDDC Manager / 管理元件
└── VI Workload Domain  ← 跑業務工作負載 (可多個)
    └── Cluster (vLCM baseline 或 vLCM image，5.2.1 可同域混用)
```

- **SDDC Manager**：負責 bring-up、Workload Domain 生命週期、自動化與 LCM。
- **vLCM 混用**：5.2.1 支援同一 Workload Domain 內同時存在 baseline 叢集與 image 叢集。
- **vLCM 轉換的關鍵限制**：5.2.1 **不支援** 將既有 baseline 叢集 *轉換 (transition)* 成 image
  叢集；此功能要到 **VCF 5.2.2** 才提供（PowerShell 腳本或 SDDC Manager API）。
  規劃升級到 VCF 9.x（僅支援 image-based）時務必注意此前置步驟。
- **升級彈性**：可從 VCF 4.5（或更新版本）做循序或跳版 (skip-level) 升級；
  管理域與所有 VI 工作負載域須升到相同版本。

## 版本與新功能

### VCF 5.2.1 BOM 核心元件

| 元件 | 版本 | Build | 日期 |
|------|------|-------|------|
| SDDC Manager | 5.2.1 | 24307856 | 2024-10-09 |
| vCenter Server | 8.0 U3c | 24305161 | 2024-10-09 |
| ESXi | 8.0 U3b | 24280767 | 2024-09-17 |
| NSX | 4.2.1 | 24304122 | 2024-10-09 |
| vSAN Witness Appliance | 8.0 U3 | 24022510 | 2024-06-19 |
| Aria Suite Lifecycle | 8.18 | 24029603 | 2024-07-23 |

（vSAN 版本隨 ESXi 8.0 U3；其餘 Aria 元件由 Aria Suite Lifecycle 管理。明細以官方 BOM 表為準。）

### 5.2.1 相對 5.2 的新功能

| 功能 | 重點 |
|------|------|
| vCenter Reduced Downtime Upgrade (RDU) | VCF 內以縮短停機方式升級 vCenter，停機可降至數分鐘等級 |
| NSX In-Place Upgrade | 搭配 vLCM baseline，NSX 升級免進入 maintenance mode |
| vLCM baseline + image 同域混用 | 同一 WLD 內可混用兩類叢集（尚不支援轉換，須到 5.2.2） |
| vSAN TiB 容量授權 | SDDC Manager UI 提供「License Now」流程套用每 TiB 容量授權 |
| Private AI Foundation | vSphere Client 導引式 NVIDIA GPU 設定；新增 DSM (Data Services Manager) 整合 |
| 憑證 / 密碼管理整合 | SDDC Manager 憑證與密碼管理整合進 vSphere Client 的 Administration |
| VPC / CCI 自助服務強化 | 開發者可自助佈建 compute/storage/network/security |
| VCF Import Tool 強化 | 5.2.1.2 配套擴大匯入範圍：shared VDS、LACP、vLCM 混合匯入 |

### 5.2.x 後續版本（升級規劃對照）

| 版本 | GA | Build | 重點 |
|------|------|-------|------|
| 5.2.1.2 | 2025-04-30 | 24690695 | 5.2.1 修補（含 Import Tool 5.2.1.2、SDDC Manager 5.2.1.1） |
| 5.2.2 | 2025-09-05 | 24936865 | vCenter/ESXi 8.0 U3g、NSX 4.2.3；首度支援 vLCM baseline→image 轉換；Bundle Transfer Utility 改為 VCF Download Tool |
| 5.2.4 | 2026-05-27 | 25437063 | vCenter/ESXi 8.0 U3j、NSX 4.2.4；主要為錯誤與安全修正（5.2.x 系列最新） |

完整細節、checklist 與來源見 `references/vcf-5.2.1.md`。

## 與其他 skill 的關係

- **`vcf-upgrade`**：5.2.x → 9.x 的跨大版本升級流程與前置盤點。
- **`vcf-9`**：VCF 9.0 / 9.1 統一架構與新功能（升級目的地）。
- **產業 / 簡報 skill**（`vcf-91-ppt`、`vcf-financial`、`vcf-telecom`、`vcf-semiconductor`、
  `vcf-hybrid-cloud`、`vcf-ai`）：需要做 VCF 簡報時改用對應 skill，並以官方範本製作。

## 重要提醒

- **文件已遷移至 Broadcom TechDocs (techdocs.broadcom.com)**；舊 docs.vmware.com 連結會轉址，
  最新內容以 TechDocs 為準。
- **vLCM 轉換誤區**：5.2.1 只能「混用」baseline 與 image，**不能轉換**；轉換是 5.2.2 才有。
- **Depot 驗證變更（KB 390098）**：2025 年 3 月起 depot URL 與驗證方式已更新，
  未更新會出現「Depot Invalid User Credential」而無法下載 bundle。
- **SSH 預設關閉（KB 86230）**：SSH service 預設停用，倚賴 SSH 的既有腳本需更新。
- 升級前須先**備份 vCenter** 與 SDDC Manager。
- **棄用事項**（列於 5.2.1 Release Notes）：Cloud Builder Appliance 及相關 API、
  部分 NSX Edge 管理工作流程、永久授權 (perpetual) 模型、部分本地化語言、
  API `POST /v1/bundles` 與 `POST /v1/product-version-catalog`。
- VCF 已轉向訂閱制；perpetual licensing 已列為棄用。

## 權威來源

- VCF 5.2.1 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-521-release-notes.html
- VCF 5.2.2 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-522-release-notes.html
- VCF 5.2.4 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-524-release-notes.html
- Upgrading Cloud Foundation: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/upgrading-cloud-foundation.html
- vLCM baseline→image 叢集轉換 (5.2.2): https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vmware-cloud-foundation-lifecycle-management/vlcm-baseline-to-vlcm-image-cluster-transition-522-lifecycle.html
