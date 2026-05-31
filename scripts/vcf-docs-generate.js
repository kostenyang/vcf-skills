export const meta = {
  name: 'vcf-docs-generate',
  description: '平行產生 5 份 VCF/VCD/HCX 完整技術 md 文件 (繁體中文)',
  phases: [{ title: '撰寫技術文件', detail: '每個主題一個 agent，產出可獨立閱讀的完整 md' }],
}

phase('撰寫技術文件')

const COMMON = `
要求：
- 全程繁體中文，技術名詞保留英文。
- 產出「可獨立閱讀」的完整技術文件 (不是 skill 觸發檔)，含目錄、章節、表格、checklist。
- 內容務必基於下方「已查證事實」，不要編造任何版本號、日期或數字。不確定的就寫「以官方文件為準」。
- 文末附「參考來源」連結清單。
- 直接回傳純 Markdown 全文，不要任何前言或解釋、不要用 code fence 包整篇。
`

const TOPICS = [
  {
    key: 'VCF9',
    title: 'VMware Cloud Foundation 9 (9.0 / 9.1) 完整技術指南',
    facts: `
VCF 9 是 Broadcom 時代第一個重大架構統一版本。
9.0 GA 日期 2025-06-17。
單一平台：統一 lifecycle 與營運層，由 VCF management services 提供共用 runtime。
VCF Installer / SDDC Manager Appliance：單一 appliance 部署 ESX/vCenter/NSX；VCF 與 VVF(vSphere Foundation) 共用安裝程式；內建 Quick Start App。
VCF Operations 取代 Aria Operations/vROps；含統一 storage dashboard(vSAN/SAN/NAS)。
VCF Automation 取代 Aria Automation。
Unified SDK：vSphere/vSAN/VCF Installer/SDDC Manager API binding 整併;9.1 達跨 Python/Java/PowerCLI/Terraform 語言一致性(OpenAPI)。
元件版本基準 vSphere9/ESX9/vSAN9/NSX9；全面 vLCM image，baseline 不再支援。
9.1 重點：host 上限翻倍至 5000；並行升級 64→256 clusters；VKS 控制平面支援至 500 clusters,provisioning 快約 70%;VM/VKS Fast-Deploy(linked clone);簡化 CaaS 自助 namespace(registry/ingress/quota/identity);Native Object Storage(S3,Tech Preview);Private AI Model & GPU Metrics(GPU 利用率/記憶體壓力/模型層級可視性);memory tiering 省約 40% server 成本;壓縮去重儲存 TCO 降約 39%;K8s 營運成本降約 46%;Unified EVPN(Arista/Cisco/SONiC)。
落地三方式:Deploy/Converge/Import。
來源:
https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0.html
https://www.vmware.com/docs/whats-new-in-vmware-cloud-foundation-9-0-solution-brief
https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes/what-s-new.html
https://www.vmware.com/docs/vmware-cloud-foundation-9-1-solution-brief
https://blogs.vmware.com/cloud-foundation/2025/07/16/vmware-cloud-foundation-9-ushers-in-new-support-model-and-release-cadence/
`,
  },
  {
    key: 'VCD',
    title: 'VMware Cloud Director (VCD 10.6 / 10.6.1) 完整技術指南',
    facts: `
VCD 是 VCSP/大型企業建構多租戶 IaaS 的管理與交付平台。
資源層級:System(Provider)->Provider VDC(PVDC,對應 vCenter resource pool+儲存+NSX)->Organization(租戶)->Org VDC(資源切片,配額)->vApp/VM/Network/Edge Gateway。
OrgVDC 配置模型:Allocation Pool / Pay-As-You-Go / Reservation Pool / Flex。
Edge Gateway 由 NSX-T 提供 NAT/FW/LB/VPN。Catalog 為 vApp/Template/ISO 內容庫。
10.6/10.6.1 新功能:
三層租戶 Multi-Tier Tenancy:Provider->Sub-Provider->Managed Org,適合 MSP/企業分層委派。
Kubernetes 細粒度授權:控制 tenant user 對 cluster 或個別 namespace 存取,多使用者共用叢集各自 namespace 部署。
VM 放置與合規:依 guest OS 定 VM Group 放到指定 host/cluster。
IP 保留期 IP Retention:sub-provider/managed org 層級自訂 IP 保留期(Static Pool/Static Manual/DHCP),VM 刪除或 NIC 移除仍保留 IP。
強制 API Token 過期:即時撤銷/失效 token。
Global Distributed Catalogs:跨區域/instance 維護內容。
IP Spaces 集中化 IP 管理。Data Center Group 跨 OrgVDC 共用 NSX-T 網路與 DFW。CSE(Container Service Extension) 提供 K8s 自助佈建。
來源:
https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-106-release-notes.html
https://blogs.vmware.com/cloudprovider/2025/02/vmware-cloud-director-10-6-1-is-here-whats-new.html
https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6.html
`,
  },
  {
    key: 'HCX',
    title: 'VMware HCX 完整技術指南 (遷移與混合雲移動)',
    facts: `
HCX 是應用遷移與工作負載移動平台,做跨站/上雲大規模低停機遷移與 L2 延伸。
核心元件:HCX Manager(來源 Connector/目的 Cloud Manager)、Interconnect(IX,加密傳輸通道)、Network Extension(NE,L2 延伸)、WAN Optimization(去重/壓縮)、Sentinel(OSAM 代理,遷移 KVM/Hyper-V)、Service Mesh(組合部署上述服務)。
部署順序:兩端裝 HCX Manager->Site Pairing->建 Network/Compute Profile->建 Service Mesh(自動部署 appliance)->遷移/延伸。
遷移類型:
Cold Migration(關機 VM 直接搬)。
HCX vMotion(跨站 live vMotion,近乎零停機,適合少量即時)。
Bulk Migration(用 vSphere Replication,平行多台,無 agent,切換窗一次重啟,適合大批量可排程)。
RAV(Replication Assisted vMotion,Replication+vMotion 結合,持續複製 delta,切換窗做 delta vMotion,大規模+低停機)。
OSAM(OS-Assisted,透過 Sentinel 遷移非 vSphere 來源)。
MON(Mobility Optimized Networking):NE 進階能力,解決 tromboning(流量繞回來源 gateway)。Bulk 遷移 VM 在 SDDC 端自動啟用 MON;vMotion/RAV 遷移 VM 預設走 on-prem gateway,需在 HCX UI/API 手動切到 cloud gateway。MON 可在延伸網段時/已延伸網段/個別 VM 三層級開關。
規模受 IX/NE appliance 數量與 WAN 頻寬限制,大規模參考官方 RAV/Bulk scalability guide。
授權:HCX Advanced(基本遷移+NE,常隨 VCF/VVF)vs HCX Enterprise(RAV/MON/OSAM 等進階)。
上雲整合:VMC on AWS / GCVE / AVS / VCF 私有雲跨站。
來源:
https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx.html
https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/vmware-hcx-user-guide-4-8/extending-networks-with-vmware-hcx/hcx-network-extension-with-mobility-optimized-networking/about-hcx-mobility-optimized-networking.html
https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-8/vmware-hcx-user-guide-4-8/migrating-virtual-machines-with-vmware-hcx/understanding-vmware-hcx-replication-assisted-vmotion.html
https://knowledge.broadcom.com/external/article/373010
`,
  },
  {
    key: 'VCF521',
    title: 'VMware Cloud Foundation 5.2.1 完整技術指南',
    facts: `
VCF 5.2.1 是 VCF 9 之前廣泛部署的 5.x 版本,傳統 SDDC Manager + Workload Domain 架構,也常作為升級到 9.0 的來源版本。
架構:SDDC Manager(LCM+自動化)管理 Management Domain(跑 vCenter/NSX/SDDC Manager/管理 VM)與多個 VI Workload Domain;Cluster 可用 vLCM baseline 或 image。元件 vSphere8.x/vSAN8.x/NSX4.x。
5.2.1 新功能:
同一 Workload Domain 內混用 vLCM baseline 與 image-based 叢集。
NSX in-place 升級:對 vLCM baseline 叢集支援,升級時不需把 host 進入 maintenance mode。
vSAN TiB 容量授權(License Now):在 SDDC Manager UI 以每 TiB 容量套用 vSAN add-on 授權。
憑證與密碼管理整合進 vSphere Client(Administration 區):憑證/整合式 CA/系統使用者密碼。
獨立 SDDC Manager 升級:SDDC Manager 升到 5.2 以上後可單獨升級取得新功能與安全修補,不必升整個 VCF BOM。
升級彈性:可從 VCF 4.5.0 或更新版本做循序或跳版(skip-level)升級到 5.2.1。
作為 9.0 升級來源前置:所有叢集 baseline->vLCM image(9 不支援 baseline);移除 ELM;修正 DVS;轉換到 9.0.1 需 vCenter>=8.0 U1a、NSX>=4.1.0.2。
來源:
https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-521-release-notes.html
https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vmware-cloud-foundation-lifecycle-management/upgrade-sddc-manager-without-upgrading-vcf-lifecycle.html
`,
  },
  {
    key: 'VCFUPGRADE',
    title: 'VMware Cloud Foundation 升級完整指南 (Deploy / Converge / Import / Upgrade)',
    facts: `
四種落地方式:Deploy(綠地新建)、Converge(既有 vSphere/vCenter+ESX 原地轉換成 VCF/VVF)、Import(既有環境匯入 VCF 管理,需求略不同於 Converge)、Upgrade(既有 VCF 往上升)。
升級路徑:VCF 4.5.0+ -> 5.2.1(循序或 skip-level);VCF 5.2 -> 5.2.1(SDDC Manager LCM bundle);VCF 5.x -> 9.0(跨大版本,重點);VCF 9.0.x -> 9.1(同系列,較單純)。
5.2->9.0 前置條件(最關鍵):
1 所有 ESX 叢集 baseline->vLCM image,須在 ESX host 升級階段之前完成(9 不支援 baseline)。
2 移除 Enhanced Linked Mode(ELM)。
3 DVS 升到支援版本。
4 元件最低版本:轉換到 9.0.0 需 ESX 先升到 9 再轉換;轉換到 9.0.1 需 vCenter>=8.0 U1a、NSX>=4.1.0.2、ESX>=8.0 U1a。
5 依現有版本可能需先升到 interim 中間版本。
6 硬體在 VCF 9 / vSAN ESA HCL。
升級順序:規劃盤點->前置 remediation(image/ELM/DVS/interim)->備份->管理域(SDDC Manager->vCenter->NSX->ESX)->工作負載域->營運/自動化(VCF Operations/Automation)->驗證收尾。
風險:每階段快照/備份,定義 rollback;skip-level 須確認受支援;9.1 並行升級達 256 clusters;5.2->9.0 是架構性升級,先在測試環境演練。
一切以 Broadcom Release Notes + Interop Matrix 為唯一準則。
來源:
https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/deployment/overview-of-deploy--converge--and-upgrade.html
https://blogs.vmware.com/cloud-foundation/2025/09/25/how-to-upgrade-to-vmware-cloud-foundation-9-0/
https://blogs.vmware.com/cloud-foundation/2025/12/18/upgrading-vmware-cloud-foundation-5-2-to-9-0-the-top-10-questions-answered/
https://blogs.vmware.com/cloud-foundation/2026/02/05/how-to-converge-a-vmware-vsphere-environment-to-vmware-cloud-foundation-9-0/
`,
  },
]

const results = await parallel(TOPICS.map(t => () =>
  agent(
    `你是資深 VMware/Broadcom 架構師。請撰寫一份標題為「${t.title}」的完整技術文件。\n${COMMON}\n\n已查證事實：\n${t.facts}`,
    { label: `寫:${t.key}`, phase: '撰寫技術文件' }
  )
))

return TOPICS.map((t, i) => ({ key: t.key, title: t.title, content: results[i] }))
