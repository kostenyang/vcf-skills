# VCF 9.1 技術參考

> 最新主要版本。GA 2026-05-12，Build 25377994（官方部落格首次公告 2026-05-05）。BOM 全元件皆為 9.1.0.0。架構基礎與 9.0 維護版詳見 `vcf-9.0.md`。

## 1. 版本與 GA 資訊

- **VCF 9.1.0.0** — GA 日期 **2026-05-12**，Build **25377994**。
- 升級至 9.1 須嚴格遵守**元件升級順序**（以官方升級指南為準）。

## 2. VCF 9.1 Bill of Materials（主要元件，皆為 9.1.0.0）

| 元件 | 版本 | Build |
|------|------|-------|
| ESX | 9.1.0.0 | 25370933 |
| vCenter | 9.1.0.0 | 25370922 |
| NSX | 9.1.0.0 | 25318225 |
| vSAN ESA Witness | 9.1.0.0 | 25370927 |
| vSAN OSA Witness | 9.1.0.0 | 25370925 |
| vSAN File Services | 9.1.0.0 | 25370922 |
| VCF Operations | 9.1.0.0 | 25346025 |
| VCF Operations for Networks | 9.1.0.0 | 25318550 |
| VCF Automation | 9.1.0.0 | 25370929 |
| VCF Installer / SDDC Manager | 9.1.0.0 | 25371088 |

> 完整 BOM 含 VCF Operations for Logs / Fleet Management 等其餘元件，以官方 BOM 頁面為準。

## 3. 新功能（依主題）

### 3.1 VCF Management Services（統一架構）
- 新增共用 runtime 與一組元件，將生命週期與營運能力的架構統一，稱為「VCF management services」。

### 3.2 基礎架構效率
- **Enhanced NVMe Memory Tiering**：hypervisor 將熱頁保留於 DRAM、冷頁卸載至本地 NVMe，擴大有效記憶體容量而不需額外 DRAM；含軟體鏡像與成本分析；官方稱可達約 **40% TCO 降低**。
- **vSAN 全域 / 擴展 Deduplication & Compression**：跨叢集類型與工作負載擴大內嵌資料縮減，支援加密資料 (at rest) 去重並改善壓縮。
- **vSphere Elastic Provisioning（Zero Touch）**：以網路影像（UEFI、HTTP/S）在裸機自動 bootstrap 與設定 ESX，無需人工介入；支援平行影像與自動發現。
- **規模**：支援多達 **5,000 台 ESX 主機**，並具備平行生命週期作業。

### 3.3 應用交付 / 開發者體驗
- **API-first 可程式化基礎架構**：以 OpenAPI 規格為單一事實來源，自動產生各語言 SDK，達成跨 Python / Java / PowerCLI / Terraform 的語言對等 (functional symmetry)。SDK 透過 Broadcom Developer Portal、PyPI、Maven Central 發布。
- **新 API 能力**：
  - **Real-Time Metrics API**：Prometheus 相容、2 秒粒度、原生 PromQL、Grafana 整合，涵蓋 ESX / vCenter / vSAN / NSX。
  - **vCenter Utilization API**。
  - **vCenter Group Federated API (VGFA)**：單一統一端點管理 vCenter group 內所有實例。
  - **vCenter Server Query API**：類 SQL 語意、伺服器端篩選與分頁。
- **統一 Java / Python SDK** 擴展涵蓋 NSX、VCF Operations、Log Management、Network Operations、Fleet / SDDC Lifecycle Management。
- **PowerCLI 9.1**：CPU topology 管理 (Assigned at PowerOn)、NVMe over TCP VMkernel、vSAN remote datastore 指令 (New/Remove-VsanRemoteDatastore)、VPC 網路 (New-VpcIpBlock、New-VpcTransitGateway、連線政策)、OAuth SSO (New-VcfOAuthSecurityContext)、ESXi proxy-backed AD 身分。
- **vSphere Terraform Provider v2.16.0**：正式支援 Project VPC、vSphere Zones、video card、CPU topology、Alarm、Cluster/VM EVC、Supervisor 等。
- **vMotion Encryption Offload**：透過硬體加速，遷移期間約節省 **70% CPU**。
- **VKS（vSphere Kubernetes Service）**：每個 Supervisor 可擴展至 **500 叢集**。
- **VKS 與 VM Fast-Deploy**：以 linked clone 技術大幅加速 VKS 與 VM 叢集的部署與升級。
- **簡化 Container-as-a-Service**：自助式 namespace 佈建，從 VCF 構件繼承 registry、ingress、quota 與 identity。
- **Native Object Storage（Tech Preview）**：開發者導向、S3 相容物件儲存，以 block/file 儲存工作流程部署管理，具 IT 治理。
- **Live Application Stack Blueprints**：擷取執行中應用並轉為可重複使用範本快速部署。

### 3.4 資安韌性 / 合規
- **Live Patching for ESX（限 TPM-enabled 主機）**：修補套用於執行中的 kernel memory，VM 持續運作、無維護視窗，涵蓋約 **80% 的修補**。
- **Advanced Cyber Compliance (ACC)**：支援持續性修復 (continuous remediation) 與統一安全態勢管理，可對 VCF 指引與 PCI DSS 基準自動評估。
- **地端勒索軟體復原**：整合 cyber recovery 至地端 VCF 隔離 clean room；vSAN for Recovery 提供原生快照式複製供災難 / 勒索復原；整合 CrowdStrike EDR 勒索復原工作流程（隔離環境掃描）。

### 3.5 生態系整合
- 網路夥伴：**Arista、Cisco、SONiC**。
- **AMD Instinct MI350 系列 GPU** 支援 DirectPath I/O。

## 4. 官方宣稱數字（核對用）

| 指標 | 數字 | 來源性質 |
|------|------|----------|
| Memory Tiering TCO 降低 | 約 40% | 官方部落格 / 文件描述 |
| vMotion Encryption Offload CPU 節省 | 約 70% | 官方描述 |
| ESX Live Patching 修補覆蓋 | 約 80% | 官方描述 |
| ESX 主機規模上限 | 5,000 | 官方描述 |
| VKS 每 Supervisor 叢集數 | 500 | 官方描述 |

> 上述數字以官方文件與實際環境為準。

## 5. 評估 / 導入 Checklist（VCF 9.1）

- [ ] 以官方 BOM 核對全部元件版本 / build 號（皆 9.1.0.0）。
- [ ] 評估 Enhanced NVMe Memory Tiering 硬體需求（本地 NVMe）與成本分析。
- [ ] 規劃 vSphere Elastic Provisioning 的網路影像基礎（UEFI / HTTP-S、DHCP/自動發現）。
- [ ] 確認 ESX Live Patching 前提：主機需 TPM-enabled。
- [ ] 規劃 API-first 整合：選定 SDK 語言（Python/Java/PowerCLI 9.1/Terraform v2.16.0）。
- [ ] 若需即時監控整合，評估 Real-Time Metrics API（Prometheus / Grafana / PromQL）。
- [ ] 合規需求對應 Advanced Cyber Compliance（PCI DSS、持續性修復）。
- [ ] 勒索復原需求評估 vSAN for Recovery clean room 與 CrowdStrike EDR 整合。
- [ ] 規模 / 並行升級規劃（至 5,000 ESX、VKS 500 叢集/Supervisor）。
- [ ] GPU 工作負載確認硬體（如 AMD Instinct MI350 DirectPath I/O）與網路夥伴 (Arista/Cisco/SONiC)。
- [ ] 升級至 9.1 前，確認元件升級順序（官方升級指南）。

## 參考來源

- VCF 9.1 What's New: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes/what-s-new.html
- VCF 9.1 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes.html
- VCF 9.1 Bill of Materials: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes/vmware-cloud-foundation-bill-of-materials.html
- VCF 9.1 公告部落格: https://blogs.vmware.com/cloud-foundation/2026/05/05/announcing-vcf-9-1-modern-private-cloud-built-for-efficiency-and-resilience/
- VCF 9.1 Programmable Infrastructure 部落格: https://blogs.vmware.com/cloud-foundation/2026/05/25/unlocking-the-full-potential-of-programmable-infrastructure-with-vmware-cloud-foundation-9-1-new-features-and-capabilities/
- VCF 9.1 Solution Brief: https://www.vmware.com/docs/vmware-cloud-foundation-9-1-solution-brief
