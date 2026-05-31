# VMware Cloud Foundation 5.2.1 技術參考

> 版本定位：VCF 5.2.1 為 VMware Cloud Foundation 5.2 系列的第一個更新版，
> 由 Broadcom 發行，GA 2024-10-09，Build 24307856。屬「VCF 5.2 and earlier」分支，
> 與新一代 VCF 9.x 為不同產品線。文件已遷移至 Broadcom TechDocs (techdocs.broadcom.com)。

## 1. 架構與元件

```
SDDC Manager (生命週期 + 自動化大腦)
├── Management Domain
│     vCenter / NSX Manager / SDDC Manager / 管理 VM
└── VI Workload Domain (x N)
      vCenter (共享或獨立) + NSX + Cluster
        └── Cluster：vLCM baseline 或 vLCM image（5.2.1 可同域混用）
```

| 層 | 元件 |
|----|------|
| LCM / 自動化 | SDDC Manager 5.2.1 |
| Compute | vSphere / ESXi 8.0 U3b |
| 儲存 | vSAN 8.0 U3（隨 ESXi，支援 ESA） |
| 網路 | NSX 4.2.1 |
| 生命週期套件 | Aria Suite Lifecycle 8.18 |
| 營運（選配，由 Aria SLCM 管理） | Aria Operations / Automation |

## 2. VCF 5.2.1 BOM（Bill of Materials）

| 元件 | 版本 | Build | 日期 |
|------|------|-------|------|
| SDDC Manager | 5.2.1 | 24307856 | 2024-10-09 |
| vCenter Server | 8.0 U3c | 24305161 | 2024-10-09 |
| ESXi | 8.0 U3b | 24280767 | 2024-09-17 |
| NSX | 4.2.1 | 24304122 | 2024-10-09 |
| vSAN Witness Appliance | 8.0 U3 | 24022510 | 2024-06-19 |
| Aria Suite Lifecycle | 8.18 | 24029603 | 2024-07-23 |

- vSAN 版本隨 ESXi 8.0 U3。
- 其餘 Aria 元件（Operations、Automation 等）由 Aria Suite Lifecycle 管理，明細以官方 BOM 表為準。

## 3. 5.2.1 新功能詳解

### 3.1 vCenter Reduced Downtime Upgrade (RDU)
- 在 VCF 內以縮短停機方式升級 vCenter，停機時間可降至數分鐘等級。

### 3.2 NSX In-Place Upgrade
- 搭配 vSphere Lifecycle Manager baseline，支援 NSX 就地 (in-place) 升級。
- 升級時不需把 host 進入 maintenance mode，降低對工作負載的衝擊。

### 3.3 同域混用 vLCM baseline 與 image
- 同一 Workload Domain 內可同時部署與升級 baseline 叢集與 image-based 叢集。
- **重要限制**：5.2.1 不支援將既有 baseline 叢集*轉換*成 image 叢集；
  轉換功能要到 **VCF 5.2.2** 才加入（PowerShell 腳本或 SDDC Manager API）。
- 這對升級到 VCF 9.x 很關鍵，因 9.x 不再支援 baseline。

### 3.4 vSAN TiB 容量授權 (License Now)
- 在 SDDC Manager UI 透過「License Now」流程套用每 TiB 容量的 vSAN 容量授權。

### 3.5 Private AI Foundation
- vSphere Client 內提供 NVIDIA GPU 基礎架構設定的導引式工作流程。
- 新增 DSM (Data Services Manager) 整合，支援 Private AI 工作負載的資料庫生命週期管理。

### 3.6 憑證與密碼管理整合進 vSphere Client
- SDDC Manager 的憑證與密碼管理整合進 vSphere Client 的 Administration 區，簡化日常維運。

### 3.7 VPC / CCI 自助服務強化
- Virtual Private Cloud (VPC) 強化，讓開發者可自助佈建 compute/storage/network/security，
  減少 IT 工單依賴；搭配 Cloud Consumption Interface (CCI) 自助服務目錄強化。

### 3.8 VCF Import Tool 強化
- 5.2.1 配套的 Import Tool（版本 5.2.1.2，搭配 SDDC Manager 5.2.1.1）擴大可匯入的
  vSphere 環境/拓樸範圍：新增 shared VDS、LACP，以及 vLCM image 與 baseline 混合的支援。

## 4. 升級到 5.2.1 / 升級路徑

- 支援從 **VCF 4.5（或更新版本）** 做循序 (sequential) 或跳版 (skip-level) 升級。
- 低於 4.5 的環境，必須先把管理域與所有 VI 工作負載域升到 4.5 以上，才能再升到 5.2.x。
- 管理域與所有 VI 工作負載域必須升級到相同版本。
- 升級透過 SDDC Manager 的 LCM 流程套用 update bundle。
- 補充：不同小版的最低起點略有差異——5.2.2 Release Notes 將支援起點描述為「4.5.2 或更新版本」，
  低於 4.5.2 須先升到 4.5.2 以上。實際以對應版本 Release Notes 為準。

## 5. 5.2.x 後續版本對照（升級規劃用）

| 版本 | GA | Build | 重點 |
|------|------|-------|------|
| 5.2.1 | 2024-10-09 | 24307856 | 5.2 系列第一個更新版 |
| 5.2.1.1 | — | — | SDDC Manager 與 Import Tool 錯誤修正 |
| 5.2.1.2 | 2025-04-30 | 24690695 | 5.2.1 修補（含 Import Tool 5.2.1.2） |
| 5.2.2 | 2025-09-05 | 24936865 | vCenter/ESXi 8.0 U3g、NSX 4.2.3、Aria SLCM 8.18 Patch 3；新增 vLCM baseline→image 轉換；Bundle Transfer Utility 改為 VCF Download Tool |
| 5.2.3 | — | — | 中間修補版 |
| 5.2.4 | 2026-05-27 | 25437063 | SDDC Manager 5.2.4、vCenter/ESXi 8.0 U3j、NSX 4.2.4；錯誤與安全修正（5.2.x 最新） |

## 6. 作為 VCF 9.x 升級來源的前置盤點

升到 VCF 9.x 前，5.2.x 環境需處理：
- [ ] 所有叢集從 baseline → vLCM image（VCF 9 不支援 baseline；轉換功能須 5.2.2+）
- [ ] 移除 Enhanced Linked Mode (ELM)
- [ ] 修正 DVS 到支援版本
- [ ] vCenter / NSX 版本符合 9.x Converge/Import 最低需求
- [ ] 確認硬體在 VCF 9 相容性清單

（完整升級流程見 `vcf-upgrade` skill。）

## 7. 重要營運注意事項

- **Depot 變更（KB 390098）**：2025 年 3 月起 depot 的驗證方式與 URL 已更新；
  未更新會出現「Depot Invalid User Credential」錯誤而無法下載 bundle。
  此事項同時列於 5.2.1 與 5.2.2 Release Notes。
- **SSH 預設關閉（KB 86230）**：SSH service 預設停用，倚賴 SSH 的既有腳本需更新。
- **升級前須先備份 vCenter**（以及 SDDC Manager 與管理元件）。

## 8. 棄用 (Deprecation) 事項（列於 5.2.1 Release Notes）

- Cloud Builder Appliance 及相關 API（朝向新部署模型）。
- 部分 NSX Edge 管理工作流程。
- 永久授權 (Perpetual licensing) 模型（VCF 已轉向訂閱制）。
- 本地化語言：義大利文、德文、簡體中文將於下一個主要版本停止支援；後續支援日文、西班牙文、法文。
- API：POST /v1/bundles 與 POST /v1/product-version-catalog。

## 9. 維運 Checklist

- [ ] 定期檢查 SDDC Manager LCM bundle / 相容性
- [ ] 確認 depot 驗證設定已更新（2025-03 後，避免 Invalid User Credential）
- [ ] 規劃 baseline → image 過渡（轉換功能須升至 5.2.2）
- [ ] vSAN 容量授權 (TiB) 監控與擴充
- [ ] 憑證 / 密碼輪替（now via vSphere Client Administration）
- [ ] 備份 vCenter、SDDC Manager 與管理元件
- [ ] 確認倚賴 SSH 的腳本已配合 SSH 預設關閉調整

## 10. 常見誤區

- 仍用 docs.vmware.com 查文件 → 已遷移至 techdocs.broadcom.com，舊連結會轉址。
- 以為 5.2.1 就能把 baseline 叢集轉成 image → 5.2.1 只能「混用」，「轉換」要到 5.2.2。
- 沿用舊 depot 設定 → 2025-03 後會失敗（Invalid User Credential）。
- 以為仍可用 perpetual 授權 → 已列為棄用，VCF 轉向訂閱制。

## 參考來源
- VCF 5.2.1 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-521-release-notes.html
- VCF 5.2.2 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-522-release-notes.html
- VCF 5.2.4 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-524-release-notes.html
- Upgrading Cloud Foundation: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/upgrading-cloud-foundation.html
- vLCM baseline→image 叢集轉換 (5.2.2): https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vmware-cloud-foundation-lifecycle-management/vlcm-baseline-to-vlcm-image-cluster-transition-522-lifecycle.html
- VCF 5.2.1 公告 (VMware Blog): https://blogs.vmware.com/cloud-foundation/2024/10/09/vmware-cloud-foundation-5-2-1-continuing-on-the-path-of-innovation-and-integration/
- VPC 強化 (VMware Blog): https://blogs.vmware.com/cloud-foundation/2024/10/29/vcf-5-2-1-virtual-private-cloud-latest-enhancements/
- VCF Import Tool 新功能 (VMware Blog): https://blogs.vmware.com/cloud-foundation/2024/12/20/new-features-available-with-the-vmware-cloud-foundation-import-tool/
