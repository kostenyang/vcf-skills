# Runbook：VCF 5.2.1 例行健檢 (唯讀)

> 目的：定期 / 升級前確認 VCF 5.2.1 環境健康。全程**唯讀**，不改動環境。
> 適用 skill：`vcf-521`。相關腳本位於 `scripts/healthcheck/`。

## 1. 前置

- 已安裝 PowerShell 7+、`VMware.PowerCLI`、`Microsoft.PowerShell.SecretManagement`。
- 已載入共用框架並設定環境檔：
  ```powershell
  Import-Module ./lib/VCFGuardrails.psm1 -Force
  Import-Module ./lib/VCFConnect.psm1   -Force
  # lib/environments.psd1 已由 example 複製並填入 uat/test/prod
  ```
- 憑證已存入 SecretManagement（每個環境的 `CredentialName`）。
- 確認操作者具備唯讀查詢權限即可（健檢不需變更權限）。

## 2. 步驟

| 步驟 | 指令 | 說明 |
| --- | --- | --- |
| 2.1 Domain/Cluster/Host | `./scripts/healthcheck/Get-Vcf521DomainHealth.ps1 -Environment <env> [-IncludeVCenter]` | 盤點所有網域、叢集、host 狀態 |
| 2.2 服務 / BOM | `./scripts/healthcheck/Get-Vcf521ServiceAndBom.ps1 -Environment <env>` | 確認 SDDC Manager 版本與各元件 build，比對 5.2.1 BOM |
| 2.3 vLCM 模式 | `./scripts/healthcheck/Get-Vcf521VlcmMode.ps1 -Environment <env>` | 列出 baseline / image，標示升 9 前須轉 image 的叢集 |
| 2.4 密碼/憑證/備份 | `./scripts/healthcheck/Get-Vcf521CertPwdBackup.ps1 -Environment <env> -ExpiryWarningDays 45` | 到期與備份狀態 |
| 2.5 (選用) 純 REST | `python3 ./scripts/healthcheck/get_vcf_inventory.py --sddc <fqdn>` | CI/排程用，需 `VCF_USERNAME/VCF_PASSWORD` 環境變數 |

## 3. 各環境注意事項

- **UAT**：可自由執行、做為腳本/輸出格式驗證場。
- **TEST**：健檢結果作為升級規劃基準；建議與 PROD 拓樸對齊。
- **PROD**：健檢為唯讀可直接執行；連線盡量於離峰、避免大量 `-IncludeVCenter` 拉取造成負載。所有結果建議留存（變更佐證）。

## 4. 驗證

- 所有 host 狀態為 `ASSIGNED/ACTIVE`、ConnectionState 為 `Connected`。
- BOM 版本符合 5.2.1（以 Broadcom Release Notes 為準）。
- 有近期 `SUCCESSFUL` 備份；無即將到期的密碼/憑證。

## 5. 回退

- 健檢為唯讀，無需回退。若 `-IncludeVCenter` 連線殘留，腳本 `finally` 會 `Disconnect-VCFAll`；必要時手動執行 `Disconnect-VCFAll`。
