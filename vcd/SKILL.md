---
name: vcd
description: |
  VMware Cloud Director (VCD) 專門知識 skill。涵蓋多租戶雲端交付平台架構、Provider/Tenant 模型、Organization、Organization VDC (OrgVDC)、Provider VDC (PVDC)、Edge Gateway、NSX 整合、Catalog/Template、三層租戶 (Three-Tier / Multi-Tier Tenancy: Provider → Sub-Provider → Managed Org)、IP Spaces、Container Service Extension (CSE)、Kubernetes 租戶/namespace 細粒度授權、Guest OS-Aware VM Placement、API Token 治理、計費與資源配額，以及 VCD 作為 VMware Cloud Foundation (VCF) 方案一部分的交付模式。當使用者詢問 VCD、Cloud Director、vCloud Director、雲服務商 (VCSP / Cloud Service Provider) 多租戶平台、租戶/組織設計、OrgVDC 規劃、IP Spaces、Edge Gateway/NSX 防火牆、VCD 版本 (10.6 / 10.6.1 / 10.6.1.2)、版本與 build 號、新功能/What's New、升級評估，或 VCD 相關架構、部署、維運、簡報、提案時觸發。技術名詞與版本一律以 Broadcom TechDocs 官方 Release Notes 為準。
---

# VMware Cloud Director (VCD)

VMware Cloud Director (VCD) 是 Broadcom (前 VMware) 的多租戶雲服務交付平台，主要供 **VMware Cloud Service Provider (VCSP)**、電信業與大型企業，在共用的 VMware 基礎架構 (vCenter + NSX + 儲存) 之上對外提供多租戶 **IaaS**。本 skill 用來回答 VCD 的架構、租戶模型、資源抽象、網路與新版功能。

> 重要交付模式更新：VCD 現以「**VMware Cloud Foundation (VCF) 方案的一部分**」交付，不再是獨立 VMware 產品線；10.6.1 即明確標示為 "as part of the VCF offering"。研究 VCSP 商業模式或授權時應據此更新。

## 使用時機

- 設計多租戶雲 (VCSP、電信、企業內部多 BU / 多子公司切分)
- 規劃 Provider VDC / Organization / Org VDC / 租戶層級
- 設計三層租戶 (Provider → Sub-Provider → Managed Org) 委派模型
- VCD 與 NSX、vCenter、VCF 的整合
- IP Spaces、Edge Gateway、Gateway Firewall、IPsec VPN 規劃
- Catalog / Template / 內容散布 (含 Global / Distributed Catalogs)
- VCD 上的 Kubernetes (CSE) 與容器服務、namespace 授權
- VCD 版本 (10.6 / 10.6.1 / 10.6.1.2)、build 號、新功能查詢與升級評估
- 撰寫 VCD 相關簡報 / 提案

## VCD 核心概念 (由上而下)

```
System (Provider / Cloud Admin)
└── Provider VDC (PVDC)   ← 對應底層 vCenter resource pool + 儲存 + NSX
    └── Organization      ← 一個租戶 (客戶)
        └── Org VDC        ← 租戶可用的資源切片 (CPU/Mem/Storage 配額)
            └── vApp / VM / Network / Edge Gateway
```

- **Provider VDC (PVDC)**：Provider 把底層 vSphere 資源抽象成資源池。
- **Organization (Org)**：一個租戶 / 客戶的邊界，含使用者、角色、目錄。
- **Organization VDC (OrgVDC)**：租戶實際消費的資源切片，定義配額與配置模型 (Allocation Pool / Pay-As-You-Go / Reservation Pool / Flex)。
- **Edge Gateway**：以 NSX 提供租戶南北向路由、NAT、防火牆、LB、VPN。
- **Catalog**：vApp Template / Template / ISO 的內容庫，可跨組織或全域散布。
- **IP Spaces**：集中化 IP 配置 / 追蹤系統 (一組不重疊的 IP ranges 與 CIDR blocks；單一 IP space 只能是 IPv4 或 IPv6)，對齊三層租戶權限模型。

## 版本與新功能

VCD 10.6 系列**目前最新版為修補版 10.6.1.2**，並非 10.6.1。

| 版本 | GA / 釋出 | Build (installed) | 性質 / 重點 |
| --- | --- | --- | --- |
| 10.6 | 27 JUN 2024 | 24055916 (24055813) | GA：三層租戶、Global/Distributed Catalogs、每 VM 多重快照、IPv6 cell、容器存取控管、規模上限大增、Photon OS 4.0 |
| 10.6.0.1 | 修補版 | — | 維護性修補 |
| 10.6.1 | 31 JAN 2025 | 24532678 (24532667) | 新功能輪：Guest OS-Aware VM Placement、API Token 強制到期/即時失效、Custom IP Retention、Gateway Firewall 可視性、Stateful Firewall 授權控管、可分享 Segment Profile、IPv6 Transparent LB；以 VCF offering 交付 |
| 10.6.1.1 | 修補版 | — | 維護性修補 |
| **10.6.1.2** | **05 DEC 2025** | **25088252 (25086345)** | **目前最新**：維護性釋出 (bug fixes + appliance base OS / 開源元件更新，約 50+ 已解決問題)，無新功能 |

「最新一輪新功能」實質來自 **10.6.1**；10.6.1.2 為純維護性修補。完整功能、修復清單與 IP Spaces 細節見 `references/vcd-10.6.md`。

關於 10.6.2：本研究在官方 TechDocs **未找到 10.6.2 的獨立 Release Notes 或 GA 資訊**，現有最高版本為 10.6.1.2 修補線。是否有 10.6.2 一律以官方文件為準。

## 與其他 skill / VCF / NSX 的關係

- VCD 疊在 vSphere + NSX 之上；在 VCF 環境中由 VCF 提供底層 SDDC，VCD 提供多租戶交付層。VCD 本身現亦以 VCF 方案的一部分交付。
- 網路服務 (Edge Gateway、segment、防火牆、LB) 由 NSX / Avi 提供，VCD 做租戶層抽象與自助。
- 撰寫電信 / VCSP 簡報時，搭配 `vcf-telecom` skill；底層 VCF 升級規劃搭配 `vcf-upgrade`、`vcf-9`、`vcf-521`。
- 災難復原 / 跨站延伸搭配 `hcx`。

## 重要提醒

- VCD 主要受眾是 **VCSP / 雲服務商**、**電信業**與需要強多租戶隔離的大型企業。
- **最新版認知**：10.6 系列最新已是 **10.6.1.2 (05 DEC 2025)**，不是 10.6.1。
- **日期需謹慎**：部分第三方站 (virten.net 等) 對 10.6.1.2 出現「2024-12-05」與 build 號互換的錯誤標示；官方 TechDocs 標示為 **05 DEC 2025**，版本日期一律以官方 Release Notes 為準。
- **外部資料庫**：10.6 起外部資料庫需 **PostgreSQL 13 或更新版本**。
- 版本功能與相容性以 Broadcom TechDocs / Release Notes 為準，不確定者標註「以官方文件為準」。

## 權威來源

- VCD 10.6 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-106-release-notes.html
- VCD 10.6.1 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-1061-release-notes.html
- VCD 10.6.1.2 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-10612-release-notes.html
- VCD 10.6 Release Notes 總覽: https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes.html
- VCD 10.6.1 What's New (Cloud Provider Blog): https://blogs.vmware.com/cloudprovider/2025/02/vmware-cloud-director-10-6-1-is-here-whats-new.html
- IP Spaces (Tenant Portal Guide): https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/map-for-vmware-cloud-director-tenant-portal-guide-10-6/working-with-networks-tenant/working-with-ip-spaces-tenant.html
- Build numbers and installer versions (Broadcom KB): https://knowledge.broadcom.com/external/article/325479/build-numbers-and-installer-versions-of.html
- Product Release Tracker (第三方，日期需與官方核對): https://www.virten.net/vmware/product-release-tracker/

## 實戰操作 (Operations)

本章節提供可在真實環境執行的 VMware Cloud Director (VCD) 腳本與 runbook，全部建構於本 repo 共用安全框架之上。

### 前置：共用 lib/ 框架 (必讀)

所有腳本都套用 `lib/` 框架，**不自己硬寫連線，不寫死密碼/IP**：

```powershell
Import-Module ./lib/VCFGuardrails.psm1 -Force   # Get-VCFEnvironment / Invoke-VCFChange
Import-Module ./lib/VCFConnect.psm1   -Force    # Get-VCFCredential (走 SecretManagement)
Import-Module ./vcd/scripts/lib/VCDApi.psm1 -Force  # VCD 專屬 REST helper (Connect-VcdApi 等)
```

- 環境一律以 `-Environment <uat|test|prod>` 帶入，由 `Get-VCFEnvironment` 解析。
- 憑證一律由 SecretManagement 取出 (`Set-Secret -Name vcd-<env> -Secret (Get-Credential)`)，使用 Provider/System 管理員帳號。
- **每個環境需在 `lib/environments.psd1` 新增 `Vcd` 欄位** (VCD Cell / Load Balancer FQDN) 與對應 `CredentialName`。
- 驗證流程依官方 API：`POST /cloudapi/1.0.0/sessions/provider` (Basic, `user@System`) → 取回 `X-VMWARE-VCLOUD-ACCESS-TOKEN` → 後續 `Authorization: Bearer`。REST 路徑/schema「以官方 VMware Cloud Director OpenAPI / Programming Guide 為準」。

### scripts/

安全分級：`healthcheck/` 與 `precheck/` = **唯讀** (只發 GET，任何環境含 PROD 可安全執行)；`change/` = **會改動環境**，一律以 `Invoke-VCFChange` 包裝 (先 dry-run 預覽、UAT/TEST 單次確認、PROD 二次確認 + 變更單號 + 備份確認)。

| 路徑 | 類型 | 說明 |
| --- | --- | --- |
| `scripts/lib/VCDApi.psm1` | 共用 | VCD REST helper：`Connect-VcdApi` / `Invoke-VcdApi` / `Get-VcdPagedResult` / `Disconnect-VcdApi`，銜接 lib/ 框架。 |
| `scripts/healthcheck/Get-VcdHealth.ps1` | 唯讀 | cell 狀態、API 版本、Org/OrgVDC 清單與配額、Edge Gateway 狀態總覽 (可 `-OutputJson`)。 |
| `scripts/healthcheck/Get-VcdCatalogSyncStatus.ps1` | 唯讀 | catalog 與 catalog item 同步/就緒狀態，標出散布卡住的內容庫。 |
| `scripts/healthcheck/vcd_tenant_usage_report.py` | 唯讀 | Python/requests，產各 Org VDC 的 CPU/記憶體/儲存配額用量表與 CSV。憑證走環境變數，不寫死。 |
| `scripts/precheck/Test-VcdUpgradeReadiness.ps1` | 唯讀 | 升級前盤點：cell、版本/build、API 相容、外部 PostgreSQL 13+ 提醒、人工確認清單。 |
| `scripts/change/New-VcdOrganization.ps1` | 變更 | 建立 Organization (租戶)。 |
| `scripts/change/New-VcdOrgVdc.ps1` | 變更 | 建立 Org VDC，含 CPU/記憶體/儲存配額與配置模型。 |
| `scripts/change/Publish-VcdCatalog.ps1` | 變更 | catalog 對外發佈 / 分享給指定 Org。 |
| `scripts/change/Set-VcdOrganizationState.ps1` | 變更 | 啟用/停用租戶 (停用視為 Destructive，PROD 需 `DESTROY` 確認)。 |

PROD 變更範例：
```powershell
./vcd/scripts/change/New-VcdOrganization.ps1 -Environment prod -OrgName acme -DisplayName 'ACME Corp' `
    -ForceProdChange -ChangeTicket CHG0012345
```

### runbooks/

| 檔案 | 用途 |
| --- | --- |
| `runbooks/vcd-healthcheck.md` | VCD 例行唯讀健檢 (cell/Org/OrgVDC/Edge/catalog/租戶用量)。 |
| `runbooks/vcd-tenant-onboarding.md` | 新租戶 onboarding：建 Org → OrgVDC → Edge，含驗證與回退。 |
| `runbooks/vcd-catalog-distribution.md` | catalog 散布：對外發佈 / 分享給租戶，含驗證與回退。 |

每份 runbook 皆含前置、步驟、UAT/TEST/PROD 各環境注意事項、驗證與回退。

### 安全提醒

- **健檢 / precheck 唯讀**：絕不改動環境，PROD 亦可安全執行；建議保存 JSON 輸出作為變更前後對照。
- **變更先測試環境**：所有 `change/` 腳本務必先在 UAT 全流程演練，再到 TEST，最後 PROD。
- **PROD 加嚴**：框架自動要求 `-ForceProdChange`、變更單號、備份確認、完整輸入環境名稱二次確認 (破壞性操作另需 `DESTROY`)。
- **不外洩**：`environments.psd1` 與密碼絕不入庫；憑證只放 SecretManagement，Python 端只透過環境變數傳入且用後即清。
- **API 正確性**：部分 OrgVDC/Edge/catalog 端點 schema 隨 API 版本而異，腳本已於註解標註「以官方 API 文件為準」，套用前請於 UAT 核對；若預設 API 版本 (38.1) 不受支援，先 `GET /api/versions` 查可用版本再以 `-ApiVersion` 指定。
