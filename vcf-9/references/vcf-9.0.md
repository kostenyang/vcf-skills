# VCF 9.0 / 9.0.1 / 9.0.2 技術參考

> 本檔涵蓋 VCF 9.0 首發及其維護版（9.0.1、9.0.2）。最新主要版本 9.1 詳見 `vcf-9.1.md`。

## 1. 版本與 GA 時間線

| 版本 | GA 日期 | Build / 性質 |
|------|---------|--------------|
| VCF 9.0（首發 / GA） | 2025-06-17 | Build 24755599，建立統一架構基礎 |
| VCF 9.0.1.0 | 2025-09-29 | 維護版，更新 BOM、聚焦可支援性 |
| VCF 9.0.2.0 | 2026-01-20 | 維護版（9.0 線最新），bug/安全修補、硬體啟用、向後相容新功能 |

> build 號部分未於 Release Notes 主頁完整列出，以官方 Bill of Materials 為準。

## 2. VCF 9.0 架構重大變革

VCF 9.0 改為統一、模組化的私有雲平台，這是相對 VCF 5.x 的根本性轉變。

### 2.1 組織階層

```
Organizational Private Cloud
  └─ VCF Fleet            （艦隊：生命週期與營運的最大邊界）
       └─ VCF Instance    （實例）
            └─ VCF Domains （管理域 / 工作負載域）
                 └─ vSphere Clusters
```

### 2.2 核心平面

- **VCF Operations = 單一統一管理介面**：整合效能監控、集中授權、Fleet 管理與整體營運，取代過去分散的工具孤島（vROps / Aria Operations 等）。
- **VCF Automation = 自助服務平面**：透過 VCF Automation Console 進行服務佈建、部署與生命週期管理（取代 Aria Automation）。
- **Fleet Management（艦隊管理）**：自動化關鍵生命週期作業 — 修補、升級、break-glass 密碼、憑證輪替等。
- 每個 Fleet **僅有一個** VCF Operations 實例與**一個** VCF Automation 實例。

### 2.3 VCF Identity Broker

- 全新現代化身分驗證服務，作為 IdP 與 VCF 元件（vCenter、NSX、VCF Operations / Automation）之間的中央身分中介。
- 支援 **SAML、OIDC**。
- 於 **Fleet 層級**套用全域設定；**ESXi 與 SDDC Manager 仍需個別設定**。

### 2.4 其他 9.0 引入能力

- VPC networking。
- 自動化憑證處理。
- converge / import 工作流程（將既有 vSphere 環境轉換 / 匯入 VCF）。

## 3. 架構認知校正（重要）

- VCF 9 已**非**傳統「SDDC Manager 為核心」的架構：自 9.0 起改以 **VCF Operations** 為統一營運平面、**VCF Automation** 為自助服務平面。
- 引入 **Fleet → Instance → Domain** 階層與 **VCF Identity Broker**。
- SDDC Manager 角色轉變，**VCF Installer / Fleet Management** 接手大量生命週期作業。
- 常見「SDDC Manager + vRealize Suite」舊認知已過時 —— vRealize 已更名整併為 VCF Operations / VCF Automation。

## 4. VCF 9.0.2.0 維護版重點（2026-01-20 GA）

維護版定位：更新 BOM，聚焦提升可支援性（bug / 安全修補、硬體啟用、向後相容新功能）。

- **vCenter 9.0.2.0**：
  - VMCA 簽發的 vCenter / ESX SSL 憑證於接近到期時**自動更新**（vCenter machine SSL 在到期少於 5 天時自動延長 2 年）。
  - Supervisor 控制平面備份於 VAMI **預設啟用**。
- **VCF Operations 9.0.2.0**：
  - Diagnostics 框架新增 **154 個 signature**（對應 148 個已知問題、4 個最佳實務、2 個基於 VMware Security Advisory）。
  - SMTP 通知外掛支援 **Microsoft 365 OAuth 2.0** 驗證。

## 5. VCF 9.0.1.0（2025-09-29 GA）

- 維護版，更新 BOM，聚焦可支援性（bug / 安全修補、硬體啟用）。

## 6. 規劃 Checklist（VCF 9.0 導入）

- [ ] 確認目標版本：新案建議直接評估 9.1，既有 9.0 環境確認是否需先升至 9.0.2。
- [ ] 規劃 Fleet / Instance / Domain 階層與邊界。
- [ ] 確認每 Fleet 單一 VCF Operations + 單一 VCF Automation 的容量規劃。
- [ ] 設計 VCF Identity Broker 與 IdP 整合（SAML / OIDC）；保留 ESXi / SDDC Manager 個別設定。
- [ ] 規劃 VPC networking 與自動化憑證處理。
- [ ] 既有環境評估 converge / import 工作流程可行性。
- [ ] 確認採 vLCM image-based 管理（baseline 已不使用）。
- [ ] 以官方 BOM 核對所有元件版本與 build 號。

## 參考來源

- VCF 9.0 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/release-notes/vmware-cloud-foundation-90-release-notes.html
- VCF 9.0.1 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/release-notes/vmware-cloud-foundation-9-0-1-release-notes.html
- VCF 9.0.2 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/release-notes/vmware-cloud-foundation-9-0-2-release-notes.html
- VCF 9.1 公告部落格（含 9.0→9.1 脈絡）: https://blogs.vmware.com/cloud-foundation/2026/05/05/announcing-vcf-9-1-modern-private-cloud-built-for-efficiency-and-resilience/
