# VMware Cloud Foundation 9.1 技術參考

> 在 9.0 統一架構基礎上，強化「可程式化基礎架構 (programmable infra)」、
> 規模 (scale)、AI 與成本效益。

## 1. 主題定位

VCF 9.1 被定位為「安全、具成本效益、可承載 production AI 的私有雲平台」。
重點在 API-first、規模翻倍、AI 可觀測性與 TCO 降低。

## 2. 核心新功能

### 2.1 API-first / OpenAPI 一致性
- 一致的 OpenAPI 消費介面，跨 **Python / Java / PowerCLI / Terraform** 語言一致 (parity)。
- 共用 runtime 與元件，統一 lifecycle 與 operational 能力（透過 VCF management services）。

### 2.2 規模 (Scale)
- host 上限**翻倍至 5000**。
- 並行升級從 **64 → 256 clusters**。
- VKS 控制平面支援至 **500 clusters**，provisioning 速度快約 **70%**。

### 2.3 快速部署 (Fast-Deploy)
- **VM Fast-Deploy / VKS Fast-Deploy**：以 linked clone 技術大幅加速 VM 與 VKS
  叢集的部署與升級。

### 2.4 容器 / 儲存服務
- **簡化版 CaaS (Container-as-a-Service)**：自助式 namespace provisioning，
  含 registry、ingress、quota、identity，皆繼承自 VCF 既有構件。
- **Native Object Storage (Tech Preview)**：開發者自助 S3 物件儲存，
  與 block / file 儲存使用相同工作流程部署。

### 2.5 AI / Private AI
- **Private AI Model & GPU Metrics**：提供 MLOps 所需遙測 — GPU 利用率、
  記憶體壓力、模型層級可視性。
- 定位為承載 production AI 的平台。

### 2.6 成本與效率
- 智慧 **memory tiering**：server 成本最高降約 **40%**。
- 強化壓縮與去重：儲存 TCO 最高降約 **39%**。
- Kubernetes 營運成本最高降約 **46%**。

### 2.7 網路
- **Unified EVPN**：橫跨 Arista、Cisco、SONiC 三大資料中心網路堆疊，
  提供一致的 overlay fabric。

## 3. 從 9.0.x 升級到 9.1

- 屬於 9.x 系列內升級（例如 9.0.2 → 9.1），相對 5.2 → 9.0 較單純。
- 仍須確認元件 BOM 與 interop，並走 VCF Operations / Lifecycle 的升級流程。
- 詳見 `vcf-upgrade` skill。

## 4. 9.1 對哪些客戶最有感

- **AI / GPU 工作負載**：Private AI Model & GPU Metrics、production AI 平台。
- **大規模環境**：5000 hosts、256 並行升級、500 VKS clusters。
- **VCSP / 雲服務商**：API-first、多租戶、CaaS。
- **重視 TCO**：memory tiering、壓縮去重、K8s 成本。

## 來源
- https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes/what-s-new.html
- https://www.vmware.com/docs/vmware-cloud-foundation-9-1-solution-brief
- https://blogs.vmware.com/cloud-foundation/2026/05/25/unlocking-the-full-potential-of-programmable-infrastructure-with-vmware-cloud-foundation-9-1-new-features-and-capabilities/
- https://news.broadcom.com/releases/broadcom-announces-vmware-cloud-foundation-9-1
- https://blogs.vmware.com/cloud-foundation/2026/05/05/vcf-9-1-secure-cost-effective-private-cloud-platform-for-production-ai/
