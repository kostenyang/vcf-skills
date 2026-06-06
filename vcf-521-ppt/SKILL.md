---
name: vcf-521-ppt
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

> 5.2.x → 9.x 的跨大版本升級流程請用 `vcf-upgrade-ppt` skill；VCF 9 架構用 `vcf-9-ppt` skill；
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

- **`vcf-upgrade-ppt`**：5.2.x → 9.x 的跨大版本升級流程與前置盤點。
- **`vcf-9-ppt`**：VCF 9.0 / 9.1 統一架構與新功能（升級目的地）。
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

## 實戰操作 (Operations)

本章節提供 VCF 5.2.1 可在真實環境執行的「腳本」與「操作手冊」，全部建立在共用框架 `lib/` 之上，遵循「唯讀健檢直接查、變更一律走護欄、先測試後正式、PROD 自動加嚴」的安全原則。

### 前置（共用框架 lib/）

所有 PowerShell 腳本均需先載入兩個模組（腳本內已自動載入）：

```powershell
Import-Module ./lib/VCFGuardrails.psm1 -Force
Import-Module ./lib/VCFConnect.psm1   -Force
```

- 環境定義集中於 `lib/environments.psd1`（由 `environments.example.psd1` 複製填寫），以 `-Environment <uat|test|prod>` 帶入，由 `Get-VCFEnvironment` 解析出 `.Tier/.SddcManager/.vCenter/.Nsx/.HcxManager`。
- 憑證一律由 SecretManagement 取得（`Get-VCFCredential` / `Get-VCFRestToken`），腳本內**不寫死密碼或 IP**。
- 變更動作一律包在 `Invoke-VCFChange` 內，提供 `-Preview`（dry-run）與 `-Action`；PROD 由框架自動要求二次確認、變更單號、備份確認。
- REST 場景另附 Python / bash 範例，同樣遵循「先預覽、PROD 二次確認、先測試環境」。

### scripts/healthcheck/（唯讀，不改動環境）

| 腳本 | 用途 |
| --- | --- |
| `Get-Vcf521DomainHealth.ps1` | SDDC Manager REST `/v1` + PowerCLI 盤點 Management/VI Workload Domain、cluster、host、vSAN 狀態 |
| `Get-Vcf521ServiceAndBom.ps1` | SDDC Manager 服務（SoS-style）、BOM/版本、各元件 build number 盤點 |
| `Get-Vcf521VlcmMode.ps1` | 盤點各 cluster 的 vLCM 模式（baseline vs image），標示升 9 前需轉 image 的叢集 |
| `Get-Vcf521CertPwdBackup.ps1` | 密碼/憑證到期、SDDC Manager 與 NSX 備份狀態盤點 |
| `get_vcf_inventory.py` | 純 REST（Python requests）跨網域盤點，CI/排程友善 |

### scripts/precheck/（升級前，唯讀為主）

| 腳本 | 用途 |
| --- | --- |
| `Test-Vcf521UpgradePrereq.ps1` | 相容性、bundle 可用性、Depot 連線（KB 390098）、SSH 狀態（KB 86230）、baseline 叢集清單檢查 |
| `check_depot_connectivity.sh` | bash/curl 快速驗證 Depot/Online Depot 連線與 token（KB 390098） |

### scripts/change/（變更，全部走 Invoke-VCFChange 護欄）

| 腳本 | 用途 |
| --- | --- |
| `Invoke-Vcf521BundleDownload.ps1` | 觸發 LCM bundle 下載 / 套用（升級 bundle） |
| `Invoke-Vcf521SddcManagerUpgrade.ps1` | SDDC Manager 獨立升級（先於其他元件） |
| `Invoke-Vcf521ApplyVsanLicense.ps1` | 套用 vSAN TiB 容量授權（License Now） |
| `Set-Vcf521HostMaintenance.ps1` | host 進入/離開維護模式（PowerCLI） |

### runbooks/

| 手冊 | 內容 |
| --- | --- |
| `vcf-521-healthcheck-runbook.md` | 5.2.1 例行健檢（唯讀）流程、各環境注意事項、驗證 |
| `vcf-521-upgrade-runbook.md` | 5.2 → 5.2.1 / skip-level 升級流程、precheck、回退 |
| `vcf-521-baseline-to-image-runbook.md` | baseline→image 規劃（轉換需 5.2.2，升 9 前必轉 image） |

### 安全分級提醒

- **唯讀**（healthcheck / 盤點 / precheck 查詢）：可直接於任何環境執行，不改動環境。
- **變更**（change/*）：務必先在 UAT/TEST 驗證；PROD 需 `-ForceProdChange` + `-ChangeTicket`，並通過備份與環境名稱二次確認。
- **破壞性**：以 `-Impact Destructive` 標示，PROD 需額外輸入 `DESTROY` 確認。
- API 路徑以官方文件為準：SDDC Manager Public API（VCF 5.2）參見 https://developer.broadcom.com/xapis/vmware-cloud-foundation-api/latest/ ；Depot 變更 KB 390098、SSH 預設關閉 KB 86230。版號/build 與相容性一律以 Broadcom TechDocs Release Notes 為準。
