# VMware Cloud Foundation 5.2.1 技術參考

## 1. 架構與元件

```
SDDC Manager (生命週期 + 自動化)
├── Management Domain
│     vCenter / NSX Manager / SDDC Manager / 管理 VM
└── VI Workload Domain (x N)
      vCenter (共享或獨立) + NSX + Cluster
        └── Cluster：vLCM baseline 或 vLCM image
```

| 層 | 元件 (5.2.1 BOM 概念) |
|----|------|
| LCM / 自動化 | SDDC Manager |
| Compute | vSphere / ESXi 8.x |
| 儲存 | vSAN 8.x（支援 ESA） |
| 網路 | NSX 4.x |
| 營運（選配） | Aria Operations / Automation 套件 |

## 2. 5.2.1 新功能詳解

### 2.1 同域混用 vLCM baseline 與 image
- 同一 Workload Domain 內可同時部署與升級 **baseline 叢集**與 **image-based 叢集**。
- 提供從 baseline 漸進遷移到 image 的過渡彈性。

### 2.2 NSX in-place 升級
- 對使用 vLCM baseline 的叢集支援 NSX **in-place 升級**。
- **不需把 host 進入 maintenance mode**，降低升級對工作負載的衝擊。

### 2.3 vSAN TiB 容量授權 (License Now)
- 在 SDDC Manager UI 透過「License Now」套用 **每 TiB 容量** 的 vSAN add-on 授權。
- 用來擴充 workload domain / cluster 的儲存容量授權。

### 2.4 憑證與密碼管理整合進 vSphere Client
- SDDC Manager 的憑證管理、整合式 CA、系統使用者密碼管理，
  現可在 **vSphere Client → Administration** 操作，簡化日常維運。

### 2.5 獨立 SDDC Manager 升級
- SDDC Manager 升到 5.2 以上後，可**單獨升級 SDDC Manager**，
  取得新功能與安全修補，而**不必升整個 VCF BOM**。

## 3. 升級到 5.2.1

- 支援從 **VCF 4.5.0 或更新版本** 升級到 5.2.1。
- 支援**循序 (sequential)** 與 **跳版 (skip-level)** 升級。
- 升級透過 SDDC Manager 的 LCM 流程，套用 update bundle。

## 4. 作為 VCF 9.0 升級來源的前置盤點

升到 VCF 9.0 前，5.2.x 環境需處理：
- [ ] 所有叢集從 **baseline → vLCM image**（VCF 9 不支援 baseline）
- [ ] 移除 **Enhanced Linked Mode (ELM)**
- [ ] 修正 **DVS** 到支援版本
- [ ] vCenter / NSX 版本符合 9.0 Converge/Import 最低需求
  - 轉換到 9.0.1：vCenter ≥ 8.0 U1a、NSX ≥ 4.1.0.2
- [ ] 確認硬體在 VCF 9 相容性清單

（完整升級流程見 `vcf-upgrade` skill。）

## 5. 維運 Checklist

- [ ] 定期檢查 SDDC Manager LCM bundle / 相容性
- [ ] 規劃 baseline → image 過渡
- [ ] vSAN 容量授權 (TiB) 監控與擴充
- [ ] 憑證 / 密碼輪替（now via vSphere Client）
- [ ] 備份 SDDC Manager 與管理元件

## 來源
- https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vcf-release-notes/vmware-cloud-foundation-521-release-notes.html
- https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vmware-cloud-foundation-lifecycle-management/upgrade-sddc-manager-without-upgrading-vcf-lifecycle.html
- https://www.virtualbytes.io/vmware-cloud-foundation-5-2-1-upgrade-troubleshooting-tips/
- https://www.viquarcloud.com/post/upgrade-vmware-cloud-foundation-5-2-to-5-2-1
