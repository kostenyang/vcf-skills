# Runbook：vLCM baseline → image 轉換規劃 (指向 5.2.2)

> 目的：規劃並執行叢集由 vLCM **baseline** 轉為 **image**。
> 關鍵限制：升級到 **VCF 9** 之前，所有叢集必須為 image 模式；而 **baseline→image 轉換功能需先升到 VCF 5.2.2**。
> 5.2.1 允許同網域 baseline / image 混用，但不提供自動轉換；轉換前請先升到 5.2.2。

## 1. 前置

- 已完成健檢（`vcf-521-healthcheck-runbook.md`）。
- 已盤點 baseline 叢集清單：
  ```powershell
  ./scripts/healthcheck/Get-Vcf521VlcmMode.ps1 -Environment <env>
  ```
- 規劃：先將環境升到 **VCF 5.2.2**（轉換功能前置），再執行轉換。
- 每個目標叢集確認硬體韌體 / driver 可由單一映像 (image) 描述（含廠商 add-on、firmware 與 HSM）。

## 2. 規劃步驟

1. 列出所有 `NeedConvert=True` 的叢集（baseline）。
2. 規劃升級到 5.2.2（流程同 `vcf-521-upgrade-runbook.md`，目標版本改 5.2.2）。
3. 為每個 baseline 叢集定義目標 image（ESXi 版本 + 廠商 add-on + firmware/驅動 add-on）。
4. 排程逐叢集轉換（建議離峰、逐叢集、保留回退視窗）。

## 3. 轉換執行（於 5.2.2）

- baseline→image 轉換在 vSphere Client / SDDC Manager 的 vLCM 流程進行（『切換為使用單一映像管理』）。
- 轉換期間可先將 host 逐台進入維護模式並校驗合規：
  ```powershell
  ./scripts/change/Set-Vcf521HostMaintenance.ps1 -Environment <env> -VMHostName <fqdn> -Action Enter
  # ... 校驗 / 修復合規 ...
  ./scripts/change/Set-Vcf521HostMaintenance.ps1 -Environment <env> -VMHostName <fqdn> -Action Exit
  ```

## 4. 各環境注意事項

- **UAT/TEST**：先在非正式叢集完整演練 image 定義與合規修復，確認 firmware/driver add-on 正確。
- **PROD**：逐叢集、維護視窗內執行；轉換前確認備份與回退視窗；host 維護模式變更走護欄（PROD 需單號 + 二次確認）。

## 5. 驗證

- 重跑 `Get-Vcf521VlcmMode.ps1`，目標叢集 `vLCMMode=image`、`NeedConvert=False`。
- 各 host 對 image 合規（compliant）。

## 6. 回退

- 轉換為單向操作（image 通常無法回退為 baseline）；故**務必先在 UAT/TEST 驗證**並備份。
- 若 host 校驗/修復失敗：以維護模式 Exit 復原服務，保留 log，必要時開 Broadcom 支援單。

> 注意：版本前置（轉換需 5.2.2）、升 9 需全 image 等規則，一律以 Broadcom TechDocs / Release Notes 最新版為準。
