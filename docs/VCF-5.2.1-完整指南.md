# VMware Cloud Foundation 5.2.1 完整指南

> 適用版本：VCF 5.2.1（GA 2024-10-09，Build 24307856）
> 文件來源：Broadcom TechDocs (techdocs.broadcom.com)
> 最後對照：2026-05；5.2.x 系列最新為 5.2.4
> 本文件為可獨立閱讀的技術指南，所有版號與相容性以官方 Release Notes 為準。

## 目錄

1. 版本定位與產品線
2. 架構總覽
3. BOM（Bill of Materials）
4. 5.2.1 新功能詳解
5. 升級路徑（循序 / 跳版）
6. vLCM baseline 與 image：混用 vs 轉換
7. 作為升級到 VCF 9.x 的來源版本
8. 重要營運注意事項
9. 棄用 (Deprecation) 事項
10. 5.2.x 後續版本對照
11. FAQ
12. Checklist
13. 參考來源

---

## 1. 版本定位與產品線

- VCF 5.2.1 是 VMware Cloud Foundation 5.2 系列的**第一個更新版**，由 Broadcom 發行。
- GA：2024-10-09，Build 24307856。
- 屬「**VCF 5.2 and earlier**」分支；新一代為 **VCF 9.x**（9.0、9.1），兩者為**不同產品線**。
- 文件已從 docs.vmware.com 遷移至 **Broadcom TechDocs (techdocs.broadcom.com)**；
  舊連結會轉址，最新內容以 TechDocs 為準。

## 2. 架構總覽

VCF 5.2.1 採傳統 **SDDC Manager + Workload Domain** 架構：

```
SDDC Manager (生命週期 LCM + 自動化大腦)
├── Management Domain
│     vCenter / NSX Manager / SDDC Manager / 管理 VM
└── VI Workload Domain (可多個)
      vCenter (共享或獨立) + NSX + Cluster
        └── Cluster：vLCM baseline 或 vLCM image（5.2.1 可同域混用）
```

- **SDDC Manager**：負責 bring-up、Workload Domain 生命週期、自動化與 LCM。
- **Management Domain**：跑 vCenter / NSX / SDDC Manager 等管理元件。
- **VI Workload Domain**：跑業務工作負載，可有多個。

## 3. BOM（Bill of Materials）

| 元件 | 版本 | Build | 日期 |
|------|------|-------|------|
| SDDC Manager | 5.2.1 | 24307856 | 2024-10-09 |
| vCenter Server | 8.0 U3c | 24305161 | 2024-10-09 |
| ESXi | 8.0 U3b | 24280767 | 2024-09-17 |
| NSX | 4.2.1 | 24304122 | 2024-10-09 |
| vSAN Witness Appliance | 8.0 U3 | 24022510 | 2024-06-19 |
| Aria Suite Lifecycle | 8.18 | 24029603 | 2024-07-23 |

- vSAN 版本隨 ESXi 8.0 U3（支援 ESA）。
- 其餘 Aria 元件（Operations、Automation 等）由 Aria Suite Lifecycle 管理；明細以官方 BOM 表為準。

## 4. 5.2.1 新功能詳解

### 4.1 vCenter Reduced Downtime Upgrade (RDU)
在 VCF 內以縮短停機方式升級 vCenter，停機時間可降至數分鐘等級。

### 4.2 NSX In-Place Upgrade
搭配 vSphere Lifecycle Manager baseline，支援 NSX 就地 (in-place) 升級，
升級時不需把 host 進入 maintenance mode。

### 4.3 同域混用 vLCM baseline 與 image
同一 Workload Domain 內可同時部署與升級 baseline 叢集與 image-based 叢集，
提供從 baseline 漸進遷移到 image 的過渡彈性。
（限制詳見第 6 節。）

### 4.4 vSAN TiB 容量授權 (License Now)
在 SDDC Manager UI 透過「License Now」流程套用每 TiB 容量的 vSAN 容量授權。

### 4.5 Private AI Foundation
- vSphere Client 內提供 NVIDIA GPU 基礎架構設定的導引式工作流程。
- 新增 DSM (Data Services Manager) 整合，支援 Private AI 工作負載的資料庫生命週期管理。

### 4.6 憑證與密碼管理整合進 vSphere Client
SDDC Manager 的憑證與密碼管理整合進 vSphere Client 的 Administration 區，簡化日常維運。

### 4.7 VPC / CCI 自助服務強化
Virtual Private Cloud (VPC) 強化，讓開發者可自助佈建 compute/storage/network/security，
減少 IT 工單依賴；搭配 Cloud Consumption Interface (CCI) 自助服務目錄強化。

### 4.8 VCF Import Tool 強化
5.2.1 配套的 Import Tool（版本 5.2.1.2，搭配 SDDC Manager 5.2.1.1）擴大可匯入的
vSphere 環境/拓樸範圍：新增 shared VDS、LACP，以及 vLCM image 與 baseline 混合的支援。

## 5. 升級路徑（循序 / 跳版）

- 支援從 **VCF 4.5（或更新版本）** 做循序 (sequential) 或跳版 (skip-level) 升級到 5.2.x。
- 低於 4.5 的環境，必須先把管理域與所有 VI 工作負載域升到 4.5 以上，才能再升到 5.2.x。
- 管理域與所有 VI 工作負載域必須升級到**相同版本**。
- 升級透過 SDDC Manager 的 LCM 流程套用 update bundle。
- 不同小版的最低起點略有差異：例如 5.2.2 Release Notes 將支援起點描述為「4.5.2 或更新版本」。
  實際以對應版本 Release Notes 為準。

## 6. vLCM baseline 與 image：混用 vs 轉換

| 能力 | VCF 5.2.1 | VCF 5.2.2+ |
|------|-----------|------------|
| 同一 WLD 內**混用** baseline 與 image 叢集 | 支援 | 支援 |
| 把既有 baseline 叢集**轉換 (transition)** 成 image | **不支援** | 支援（PowerShell 腳本 / SDDC Manager API） |

- **關鍵誤區**：很多人以為 5.2.1 就能把 baseline 轉成 image，實際上只能「混用」。
- 轉換是規劃升級到 **VCF 9.x 的前置步驟**，因 9.x **僅支援 image-based、不再支援 baseline**。

## 7. 作為升級到 VCF 9.x 的來源版本

升到 VCF 9.x 前，5.2.x 環境需處理：

- [ ] 所有叢集從 baseline → vLCM image（轉換功能須升至 5.2.2+）
- [ ] 移除 Enhanced Linked Mode (ELM)
- [ ] 修正 DVS 到支援版本
- [ ] vCenter / NSX 版本符合 9.x Converge/Import 最低需求
- [ ] 確認硬體在 VCF 9 相容性清單

（完整跨大版本升級流程請參考 VCF 升級專屬文件 / `vcf-upgrade` skill。）

## 8. 重要營運注意事項

- **Depot 變更（KB 390098）**：2025 年 3 月起 depot 的驗證方式與 URL 已更新；
  未更新會出現「Depot Invalid User Credential」錯誤而無法下載 bundle。
  此事項同時列於 5.2.1 與 5.2.2 Release Notes。
- **SSH 預設關閉（KB 86230）**：SSH service 預設停用，倚賴 SSH 的既有腳本需更新。
- **升級前須先備份 vCenter**（以及 SDDC Manager 與管理元件）。

## 9. 棄用 (Deprecation) 事項（列於 5.2.1 Release Notes）

- Cloud Builder Appliance 及相關 API（朝向新部署模型）。
- 部分 NSX Edge 管理工作流程。
- 永久授權 (Perpetual licensing) 模型；VCF 已轉向訂閱制。
- 本地化語言：義大利文、德文、簡體中文將於下一個主要版本停止支援；後續支援日文、西班牙文、法文。
- API：`POST /v1/bundles` 與 `POST /v1/product-version-catalog`。

## 10. 5.2.x 後續版本對照

| 版本 | GA | Build | 重點 |
|------|------|-------|------|
| 5.2.1 | 2024-10-09 | 24307856 | 5.2 系列第一個更新版 |
| 5.2.1.2 | 2025-04-30 | 24690695 | 5.2.1 修補（含 Import Tool 5.2.1.2、SDDC Manager 5.2.1.1） |
| 5.2.2 | 2025-09-05 | 24936865 | vCenter/ESXi 8.0 U3g、NSX 4.2.3、Aria SLCM 8.18 Patch 3；新增 vLCM baseline→image 轉換；Bundle Transfer Utility 改為 VCF Download Tool |
| 5.2.3 | — | — | 中間修補版 |
| 5.2.4 | 2026-05-27 | 25437063 | SDDC Manager 5.2.4、vCenter/ESXi 8.0 U3j、NSX 4.2.4；錯誤與安全修正（5.2.x 最新） |

## 11. FAQ

**Q：VCF 5.2.1 可以把 baseline 叢集轉成 image 叢集嗎？**
A：不行。5.2.1 只支援同一 Workload Domain 內混用；轉換 (transition) 功能要到 5.2.2，
透過 PowerShell 腳本或 SDDC Manager API 執行。

**Q：可以從哪個版本升級到 5.2.1？**
A：VCF 4.5（或更新版本）皆可，支援循序與跳版。低於 4.5 須先升到 4.5 以上。
管理域與所有 VI 工作負載域要升到相同版本。

**Q：下載 bundle 出現「Depot Invalid User Credential」怎麼辦？**
A：2025 年 3 月起 depot URL 與驗證方式已變更，需依 KB 390098 更新設定。

**Q：為什麼 SSH 連不上？**
A：SSH service 在 5.2.1 預設停用（KB 86230）；倚賴 SSH 的腳本需調整或改用其他方式。

**Q：VCF 5.2.1 還能用永久授權嗎？**
A：perpetual licensing 已列為棄用；VCF 已轉向訂閱制。

**Q：5.2.x 最新版本是哪個？**
A：截至 2026-05 為 VCF 5.2.4（GA 2026-05-27，Build 25437063）。

**Q：VCF 5.2.1 跟 VCF 9.x 是同一條線嗎？**
A：不是。5.2.x 屬「VCF 5.2 and earlier」分支，9.x 為新一代不同產品線；5.2.x 常作為升級到 9.x 的來源。

## 12. Checklist

維運：
- [ ] 定期檢查 SDDC Manager LCM bundle / 相容性
- [ ] 確認 depot 驗證設定已更新（2025-03 後）
- [ ] 規劃 baseline → image 過渡（轉換須 5.2.2+）
- [ ] vSAN 容量授權 (TiB) 監控與擴充
- [ ] 憑證 / 密碼輪替（now via vSphere Client Administration）
- [ ] 備份 vCenter、SDDC Manager 與管理元件
- [ ] 確認倚賴 SSH 的腳本已配合 SSH 預設關閉調整

升級到 9.x 前置：
- [ ] 所有叢集轉為 vLCM image
- [ ] 移除 ELM
- [ ] 修正 DVS 版本
- [ ] vCenter / NSX 符合 9.x 最低需求
- [ ] 硬體在 VCF 9 相容性清單

## 13. 參考來源

- VCF 5.2.1 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-521-release-notes.html
- VCF 5.2.2 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-522-release-notes.html
- VCF 5.2.4 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-524-release-notes.html
- Upgrading Cloud Foundation: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/upgrading-cloud-foundation.html
- vLCM baseline→image 叢集轉換 (5.2.2): https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vmware-cloud-foundation-lifecycle-management/vlcm-baseline-to-vlcm-image-cluster-transition-522-lifecycle.html
- VCF 5.2.1 公告 (VMware Blog): https://blogs.vmware.com/cloud-foundation/2024/10/09/vmware-cloud-foundation-5-2-1-continuing-on-the-path-of-innovation-and-integration/
- VPC 強化 (VMware Blog): https://blogs.vmware.com/cloud-foundation/2024/10/29/vcf-5-2-1-virtual-private-cloud-latest-enhancements/
- VCF Import Tool 新功能 (VMware Blog): https://blogs.vmware.com/cloud-foundation/2024/12/20/new-features-available-with-the-vmware-cloud-foundation-import-tool/
