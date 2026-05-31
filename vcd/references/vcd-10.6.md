# VMware Cloud Director 10.6 / 10.6.1 技術參考

## 1. 租戶模型 (Tenancy)

### 1.1 三層租戶 (Multi-Tier Tenancy)
VCD 10.6 引入三層架構，讓 Provider 把管理權委派下去：

```
Provider (System)
└── Sub-Provider        ← 例如：經銷商 / 大區
    └── Managed Org      ← 最終租戶 (客戶)
```

- 適合 MSP（多層轉售）或大型企業內部分層 (例如：總部 → 子公司 → BU)。
- 每層可有獨立的角色、配額與委派管理。

### 1.2 資源抽象
- **Provider VDC (PVDC)**：底層 vCenter resource pool + datastore + NSX 的抽象。
- **Organization VDC (OrgVDC)** 配置模型：
  - *Allocation Pool*：配置一定比例保證資源。
  - *Pay-As-You-Go*：用多少算多少，無前置保留。
  - *Reservation Pool*：完整保留，租戶自行超分。
  - *Flex*：彈性混合模型 (10.x 主推)。

## 2. 網路 (NSX-T 整合)

- **Edge Gateway**：租戶南北向，提供 NAT / FW / LB / IPSec & L2 VPN。
- **Org VDC Network**：Routed / Isolated / Imported。
- **Data Center Group**：跨多個 OrgVDC 共用 NSX-T 網路與分散式防火牆 (DFW)。
- **IP Spaces**：集中化 IP 管理（public / private / shared），取代傳統 external network 配 IP 的方式。

## 3. Kubernetes / 容器

- **Container Service Extension (CSE)**：在 VCD 上提供 Tanzu / TKG 叢集自助佈建。
- 10.6 起支援 **K8s 細粒度授權**：可控制 tenant 使用者對叢集或個別 namespace 的存取，
  多使用者共用一叢集、各自 namespace 部署應用。

## 4. 內容管理 (Catalog)

- **Global Distributed Catalogs**：跨區域 / 跨 VCD instance 同步維護 vApp / Template / ISO。
- 支援 published / subscribed catalog 訂閱模型。

## 5. 10.6 / 10.6.1 新功能清單

| 功能 | 說明 |
|------|------|
| Multi-Tier Tenancy | Provider → Sub-Provider → Managed Org 三層委派 |
| K8s 細粒度授權 | 控制 tenant user 對 cluster / namespace 的存取 |
| VM 放置與合規 | 依 guest OS 定 VM Group，放到指定 host/cluster |
| IP Retention | sub-provider / managed org 層級自訂 IP 保留期 |
| 強制 API Token 過期 | 即時撤銷 / 失效 API token |
| Global Distributed Catalogs | 跨區域 / instance 維護內容 |

## 6. 部署與架構建議

- VCD cell 通常多節點 + 共用 NFS transfer share + 外部資料庫 (PostgreSQL)。
- 前端可放 load balancer；多 cell 提供 HA。
- 與 vCenter / NSX-T Manager 以 API 整併；在 VCF 環境疊於 SDDC 之上。

## 7. 規劃 Checklist

- [ ] 決定租戶層級（單層 vs 三層）
- [ ] PVDC 與底層 vСenter / 儲存 / NSX 對應
- [ ] OrgVDC 配置模型（Flex / PAYG / Allocation / Reservation）
- [ ] IP Spaces 與外部網路規劃
- [ ] Edge Gateway 與 DFW 策略
- [ ] Catalog 散布策略
- [ ] 是否導入 CSE / K8s 自助

## 來源
- https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-106-release-notes.html
- https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-1061-release-notes.html
- https://blogs.vmware.com/cloudprovider/2025/02/vmware-cloud-director-10-6-1-is-here-whats-new.html
- https://virtualbytes.io/vmware-cloud-director-10-6-1-taking-cloud-management-to-new-heights/
