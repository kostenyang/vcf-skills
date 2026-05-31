---
name: vcd
description: >-
  VMware Cloud Director (VCD) 專門知識 skill。涵蓋多租戶雲端管理、Provider/Tenant、
  Organization、Organization VDC (OrgVDC)、Provider VDC、Edge Gateway、NSX-T 整合、
  Catalog/Template、三層租戶 (multi-tier tenancy)、Container Service Extension (CSE)、
  Kubernetes 租戶管理、App Launchpad、計費與資源配額。當使用者詢問 VCD、Cloud Director、
  雲服務商 (VCSP) 多租戶平台、租戶/組織設計、OrgVDC 規劃、VCD 10.6/10.6.1、
  或 VCD 相關架構、部署、維運、簡報時觸發。
---

# VMware Cloud Director (VCD)

VMware Cloud Director 是雲服務商 (VCSP) 與大型企業用來建構「多租戶 IaaS / 私有雲」
的管理與交付平台。本 skill 用來回答 VCD 的架構、租戶模型、資源抽象與新版功能。

## 使用時機

- 設計多租戶雲（VCSP、企業內部多 BU 切分）
- 規劃 Provider VDC / Organization VDC / Org / 租戶層級
- VCD 與 NSX-T、vCenter、VCF 的整合
- Catalog / Template / 內容散布規劃
- VCD 上的 Kubernetes（CSE）與容器服務
- VCD 10.6 / 10.6.1 新功能查詢與升級評估
- 撰寫 VCD 相關簡報 / 提案

## VCD 核心概念 (由上而下)

```
System (Provider / Cloud Admin)
└── Provider VDC      ← 對應底層 vCenter resource pool + 儲存 + NSX
    └── Organization  ← 一個租戶 (客戶)
        └── Org VDC    ← 租戶可用的資源切片 (CPU/Mem/Storage 配額)
            └── vApp / VM / Network / Edge Gateway
```

- **Provider VDC (PVDC)**：Provider 把底層 vSphere 資源抽象成資源池。
- **Organization (Org)**：一個租戶 / 客戶的邊界，含使用者、角色、目錄。
- **Organization VDC (OrgVDC)**：租戶實際消費的資源切片，定義配額與分配模型
  （Allocation Pool / Pay-As-You-Go / Reservation Pool / Flex）。
- **Edge Gateway**：以 NSX-T 提供租戶南北向路由、NAT、防火牆、LB、VPN。
- **Catalog**：vApp / Template / ISO 的內容庫，可跨組織或全域散布。

## VCD 10.6 / 10.6.1 重點新功能

- **三層租戶 (Multi-Tier Tenancy)**：Provider → Sub-Provider → Managed Org，
  適合 MSP 或企業內部分層委派管理。
- **Kubernetes 細粒度授權**：可控制個別 tenant 使用者對 K8s 叢集或 namespace 的存取，
  多使用者共用叢集、各自在不同 namespace 部署。
- **VM 放置與合規**：依 guest OS 定義 VM Group，將 VM 放到指定 host/cluster，
  確保跨租戶的放置與合規。
- **IP 保留期 (IP Retention)**：sub-provider 與 managed org 層級可自訂 IP 保留期，
  即使 VM 刪除或 NIC 移除仍可保留 IP（適用 Static Pool / Static Manual / DHCP）。
- **強制 API Token 過期**：可即時撤銷 / 失效 API token，提升安全。
- **全域散布目錄 (Global Distributed Catalogs)**：跨區域 / 跨 instance 維護內容更簡單。

詳細內容見 `references/vcd-10.6.md`。

## 與 VCF / NSX 的關係

- VCD 通常疊在 vSphere + NSX-T 之上；在 VCF 環境中由 VCF 提供底層 SDDC，
  VCD 提供多租戶交付層。
- 網路服務（Edge、segment、防火牆）由 NSX-T 提供，VCD 做租戶層抽象與自助。

## 重要提醒

- VCD 主要受眾是 **VCSP / 雲服務商**與需要強多租戶隔離的大型企業。
- 版本功能與相容性以 Broadcom TechDocs / Release Notes 為準。

## 權威來源
- VCD 10.6 Release Notes: https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/release-notes/vmware-cloud-director-106-release-notes.html
- VCD 10.6.1 What's New: https://blogs.vmware.com/cloudprovider/2025/02/vmware-cloud-director-10-6-1-is-here-whats-new.html
- VCD 10.6 文件首頁: https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6.html
