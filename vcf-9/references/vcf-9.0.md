# VMware Cloud Foundation 9.0 技術參考

> GA 日期：2025-06-17。VCF 9 系列的第一個版本，奠定統一架構基礎。

## 1. 定位與設計目標

VCF 9.0 的主軸是「簡化私有雲營運、提升效能、強化安全」，把原本分散的
SDDC 元件與 Aria 套件整併為單一平台，從單一介面完成「建置 → 營運 → 安全」。

## 2. 主要元件 (BOM 概念)

| 層 | 元件 | VCF 9.0 對應 |
|----|------|------|
| 安裝 / LCM | VCF Installer + SDDC Manager Appliance | 單一 appliance 部署全部元件 |
| Compute | ESX 9.0 | baseline 已淘汰，僅 vLCM image |
| 管理平面 | vCenter 9.0 | — |
| 儲存 | vSAN 9.0 | 統一 storage dashboard（vSAN/SAN/NAS） |
| 網路 | NSX 9.0 | — |
| 營運 | VCF Operations | 取代 Aria Operations / vROps |
| 自動化 | VCF Automation | 取代 Aria Automation |
| K8s | VKS (vSphere Kubernetes Service) | 容器與 K8s 服務 |

## 3. 關鍵新特性

### 3.1 Unified Installer / SDDC Manager Appliance
- VCF 與 VVF (vSphere Foundation) 共用同一安裝程式。
- 從 installer 直接部署 ESX、vCenter 與其他元件。
- 內建 Quick Start App，降低初期設定複雜度，並整合治理 (governance)。

### 3.2 VCF Operations Console
- 單一介面進行建置、營運與安全。
- 統一 storage dashboard：儲存庫存、效能、使用率與成本，含容量規劃；
  對 vSAN / SAN / NAS 提供即時可視性。

### 3.3 Unified SDK / API
- VCF 9.0 開始將 vSphere、vSAN、VCF Installer、SDDC Manager 的 API binding
  整併成單一 Unified SDK（9.1 進一步達成跨語言一致性）。

### 3.4 生命週期管理
- 全面採用 vLCM image-based 叢集管理。
- **baseline 管理在 VCF 9 不再支援**（自 5.x 升級前必須先轉成 image）。

## 4. 部署 / 轉換 / 匯入 (Deploy / Converge / Import)

VCF 9.0 提供三種落地路徑：
- **Deploy**：全新部署。
- **Converge**：將既有 vSphere/vCenter + ESX 轉換成 VCF/VVF 平台（原地納管）。
- **Import**：把既有環境匯入 VCF 管理。

轉換/匯入的前置條件（重點）：
- 轉換到 9.0.0：ESX 必須先升到 9。
- 轉換到 9.0.1：vCenter 需 8.0 U1a 以上、NSX 需 4.1.0.2 以上，ESX 可在 8.0 U1a 以上。
- 須先移除 Enhanced Linked Mode (ELM)、修正 DVS 版本等不相容組態。
- 所有叢集須由 baseline 轉為 vLCM image。

（完整升級流程見 `vcf-upgrade` skill。）

## 5. 支援模式與發布節奏

VCF 9 導入新的支援模式與 release cadence，規劃時須確認各元件的支援生命週期，
避免落在不受支援的中間版本。

## 6. 規劃 Checklist

- [ ] 確認硬體在 VCF 9 / vSAN ESA 相容性清單
- [ ] 所有叢集已 image 化 (vLCM image)
- [ ] 移除 ELM、修正 DVS / 不相容組態
- [ ] 規劃 VCF Operations / Automation 資源
- [ ] IP / DNS / NTP / 憑證 規劃
- [ ] 確認來源版本符合 Converge/Import 最低版本需求

## 來源
- https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0.html
- https://www.vmware.com/docs/whats-new-in-vmware-cloud-foundation-9-0-solution-brief
- https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/release-notes/vmware-cloud-foundation-90-release-notes.html
- https://blogs.vmware.com/cloud-foundation/2025/07/16/vmware-cloud-foundation-9-ushers-in-new-support-model-and-release-cadence/
