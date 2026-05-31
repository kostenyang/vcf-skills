---
name: vcf-9
description: >-
  VMware Cloud Foundation 9 (9.0 與 9.1) 專門知識 skill。涵蓋 VCF 9 統一架構、
  VCF Installer / SDDC Manager Appliance、VCF Operations、VCF Automation、單一 OpenAPI、
  vSphere 9 / ESX 9 / vSAN 9 / NSX 9、VKS (Kubernetes)、Fleet Management、
  以及 9.0 與 9.1 的差異與新功能。當使用者詢問 VCF 9、VCF 9.0、VCF 9.1、
  vSphere Foundation 9、私有雲架構、VCF 9 部署/規劃/設計、或任何 9.x 技術細節時觸發。
  也適用於 VCF 9 簡報、POC、架構設計、版本比較等需求。
---

# VMware Cloud Foundation 9 (9.0 / 9.1)

VCF 9 是 Broadcom 收購 VMware 後的第一個「重大架構統一」版本，把過去鬆散的
SDDC + Aria 套件，整併成單一平台、單一安裝程式、單一 API。本 skill 用來回答
VCF 9.0 與 9.1 的架構、元件、部署、規劃與版本差異。

## 使用時機

- 規劃或設計 VCF 9 私有雲架構
- 比較 VCF 9.0 vs 9.1，或 VCF 9 vs VCF 5.x
- VCF 9 元件版本、相容性、BOM 查詢
- VCF 9 部署 (Deploy)、轉換 (Converge)、匯入 (Import)
- 撰寫 VCF 9 簡報、POC 計畫、技術文件

> 升級流程 (5.2 → 9.0、9.0 → 9.1) 請改用 `vcf-upgrade` skill。

## VCF 9 核心架構重點

1. **單一平台 (Unified Platform)**：VCF 9 不再是「vSphere + vSAN + NSX + Aria 拼裝」，
   而是統一生命週期與營運層，由 VCF management services 提供共用 runtime。
2. **VCF Installer / SDDC Manager Appliance**：單一 appliance 即可部署 ESX、vCenter、
   NSX 等。VCF 與 VVF (vSphere Foundation) 共用同一安裝程式。
3. **VCF Operations**：取代過去的 vROps / Aria Operations，提供建置、營運、安全
   的單一介面 (含 Quick Start App)。內含統一 storage dashboard（vSAN/SAN/NAS）。
4. **VCF Automation**：取代 Aria Automation，提供自助式服務與 IaC。
5. **Unified SDK / OpenAPI**：vSphere、vSAN、VCF Installer、SDDC Manager API
   binding 整併成單一 Unified SDK，9.1 進一步達成跨 Python / Java / PowerCLI /
   Terraform 的語言一致性 (language parity)。
6. **元件版本基準**：vSphere 9 / ESX 9 / vSAN 9 / NSX 9。VCF 9 全面採用 vLCM
   image-based 管理，**baseline 管理已不再支援**。

## 9.0 與 9.1 的差異（速查）

| 主題 | VCF 9.0 (GA 2025-06-17) | VCF 9.1 |
|------|------|------|
| 定位 | 建立統一架構基礎 | 強化 programmable infra、AI、規模 |
| API | 開始整併 Unified SDK | OpenAPI 跨語言一致性 (Python/Java/PowerCLI/Terraform) |
| 規模 | — | host 上限翻倍至 5000，並行升級 64 → 256 clusters |
| K8s (VKS) | VKS 基礎 | 控制平面支援至 500 clusters，provisioning 快 70% |
| 部署 | — | VM / VKS Fast-Deploy（linked clone），CaaS 自助 namespace |
| 儲存 | 統一 storage dashboard | Native Object Storage (S3, Tech Preview)、壓縮去重 TCO 降約 39% |
| AI | Private AI Foundation | Private AI Model & GPU Metrics（利用率/記憶體壓力/模型層級可視性） |
| 成本 | — | memory tiering 省約 40% server 成本、K8s 營運成本降約 46% |
| 網路 | — | Unified EVPN（Arista / Cisco / SONiC） |

詳細內容見：
- `references/vcf-9.0.md`
- `references/vcf-9.1.md`

## 重要提醒

- VCF 9 採新的支援模式與發布節奏 (release cadence)，規劃時務必確認支援生命週期。
- 從 VCF 5.x 升級到 9.0 有大量前置條件（vLCM image 化、移除 ELM、DVS 版本等），
  細節請用 `vcf-upgrade` skill。
- 版本與相容性數字會隨更新變動，正式專案請以 Broadcom TechDocs / Release Notes 為準。

## 權威來源

- VCF 9.0 TechDocs: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0.html
- VCF 9.1 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes.html
- What's New in VCF 9.0 (solution brief): https://www.vmware.com/docs/whats-new-in-vmware-cloud-foundation-9-0-solution-brief
- What's New in VCF 9.1 (solution brief): https://www.vmware.com/docs/vmware-cloud-foundation-9-1-solution-brief
