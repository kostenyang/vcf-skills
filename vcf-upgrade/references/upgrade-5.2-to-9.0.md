# VCF 升級技術參考：5.2 → 9.0（含 Converge / Import）與 9.0 → 9.1

## 1. 全景：四種落地方式

| 方式 | 起點 | 終點 | 一句話 |
|------|------|------|--------|
| Deploy | 無 | VCF 9 | 綠地新建 |
| Converge | 既有 vSphere/vCenter + ESX | VCF / VVF 平台 | 原地轉換納管 |
| Import | 既有環境 | VCF 管理 | 匯入納管（需求略不同於 Converge） |
| Upgrade | 既有 VCF | 較新 VCF | 版本往上升 |

> Converge 與 Import 的需求「大致相同、細節有差」。Converge 偏「轉換」，
> Import 偏「匯入既有」。

## 2. 5.2 → 9.0：前置條件全清單

### 2.1 生命週期 (LCM)
- [ ] 所有 ESX 叢集從 **baseline → vLCM image**（9 不支援 baseline）。
- [ ] image 化須在 **ESX host 升級階段之前**完成。

### 2.2 組態 remediation
- [ ] 移除 **Enhanced Linked Mode (ELM)**。
- [ ] **DVS** 升到支援版本。
- [ ] 清理其他不相容組態（依 precheck 結果）。

### 2.3 元件最低版本（依目標版本）
| 目標 | vCenter | NSX | ESX |
|------|---------|-----|-----|
| 9.0.0 | — | — | 須先升到 **9** 再轉換 |
| 9.0.1 | ≥ 8.0 U1a | ≥ 4.1.0.2 | ≥ 8.0 U1a |

### 2.4 中間步驟 (interim)
- 依現有 vSphere / NSX / VCF Operations 版本，可能需先升到中間版本，
  再進 9.0。務必查 Interop Matrix 與 Release Notes。

### 2.5 硬體
- [ ] 確認在 VCF 9 / vSAN ESA HCL。

## 3. Converge 既有 vSphere → VCF 9.0 流程概念

1. 前置 precheck（ELM、DVS、版本、HCL）。
2. 完成 remediation（image 化、移除 ELM、DVS 升版）。
3. 元件升到符合目標 9.0.x 的最低版本（必要時走 interim）。
4. 執行 Converge：把 vCenter instance + ESX hosts 納入 VCF/VVF。
5. 驗證納管狀態、LCM、營運面。

## 4. 升級順序（管理域優先）

```
1. 規劃 / 盤點
2. 前置 remediation (image / ELM / DVS / interim)
3. 備份 (SDDC Manager / vCenter / NSX / 設定)
4. 管理域：SDDC Manager → vCenter → NSX → ESX
5. 工作負載域：vCenter → NSX → ESX (逐域)
6. 營運 / 自動化：VCF Operations / Automation
7. 驗證 + 收尾
```

## 5. 9.0.x → 9.1 升級

- 屬同系列升級（例：9.0.2 → 9.1），相對單純。
- 仍須：
  - [ ] 對 BOM / interop（確認各元件目標版本）。
  - [ ] 走 VCF Operations / Lifecycle 升級流程。
  - [ ] 利用 9.1 的並行升級能力（最高 256 clusters）規劃維護窗。

## 6. 風險、回退與維護窗

- 每階段前快照 / 備份；定義 rollback 點。
- skip-level（跳版）省時間，但須確認該路徑「受支援」。
- 大規模環境評估並行升級能力與維護窗長度。
- 5.2 → 9.0 是**架構性升級**，建議先在測試 / staging 完整演練。

## 7. 升級專案 Checklist（總表）

- [ ] 盤點現有版本（VCF / vCenter / NSX / ESX / vSAN / Operations）
- [ ] 對 Interop Matrix，決定是否需 interim 版本
- [ ] 所有叢集 image 化
- [ ] 移除 ELM、修正 DVS
- [ ] 元件達目標 9.0.x 最低版本
- [ ] HCL 確認
- [ ] 全面備份
- [ ] 排定維護窗與 rollback 方案
- [ ] 測試環境演練
- [ ] 正式升級（管理域 → 工作負載域 → 營運層）
- [ ] 升級後驗證

## 來源
- https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/deployment/overview-of-deploy--converge--and-upgrade.html
- https://blogs.vmware.com/cloud-foundation/2025/09/25/how-to-upgrade-to-vmware-cloud-foundation-9-0/
- https://blogs.vmware.com/cloud-foundation/2025/11/20/upgrading-vmware-cloud-foundation-5-2-to-9-0-webinar-takeaways/
- https://blogs.vmware.com/cloud-foundation/2025/12/18/upgrading-vmware-cloud-foundation-5-2-to-9-0-the-top-10-questions-answered/
- https://blogs.vmware.com/cloud-foundation/2026/02/05/how-to-converge-a-vmware-vsphere-environment-to-vmware-cloud-foundation-9-0/
- https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/deployment/converging-your-existing-vsphere-infrastructure-to-a-vcf-or-vvf-platform-/supported-scenarios-to-converge-to-vcf/converge-your-existing-vcenter-instance-and-esx-hosts.html
- https://angrysysops.com/2026/05/27/upgrading-vmware-cloud-foundation-from-9-0-2-to-9-1-practical-runbook-notes/
