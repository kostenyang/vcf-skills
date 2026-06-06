# Runbook：VCF 升級前置盤點 (Precheck)

> 目的：在動任何升級之前，先把環境盤點清楚，確認是否符合目標版本最低需求與 VCF 9 的硬性前提（vLCM image、停用 ELM、DVS 版本、備份）。
>
> 本 runbook 的腳本**全部唯讀**，不改動環境。最終可行性與最低版本一律以官方 **VCF Upgrade Planning Tool**（<https://vmware.github.io/vcf-upgrade-planner/>）與目標版本 **Release Notes** 為準。

## 前置

1. 安裝相依：`VMware.PowerCLI`、`Microsoft.PowerShell.SecretManagement`（Python 盤點另需 `requests`；bash 觸發需 `curl`、`jq`）。
2. 建立環境定義：複製 `lib/environments.example.psd1` 為 `lib/environments.psd1`，填入 UAT/TEST/PROD FQDN 與 `CredentialName`。
3. 寫入憑證到 SecretManagement（**不要寫死密碼**）：
   ```powershell
   Set-Secret -Name vcf-uat  -Secret (Get-Credential)
   Set-Secret -Name vcf-test -Secret (Get-Credential)
   Set-Secret -Name vcf-prod -Secret (Get-Credential)
   ```
4. 先在 **UAT** 跑通，再 TEST，最後 PROD。

## 步驟

### 步驟 1：官方規劃工具（必做，先做）

用 VCF Upgrade Planning Tool 輸入現況（vSphere/VCF、目前版本），取得官方建議的目標版本、分階段流程與資源/網路需求，匯出 PDF 存檔。腳本盤點是輔助，不能取代此步。

### 步驟 2：全面盤點報表（PowerCLI，唯讀）

```powershell
./scripts/precheck/Invoke-VCFUpgradePrecheck.ps1 -Environment uat -TargetVersion 9.1.0 -OutputDir ./precheck-reports
```

產出 `*.html / *.csv / *.json`，逐項顯示 PASS/WARN/FAIL，涵蓋：

- 元件版本（SDDC Manager / NSX / vCenter / ESXi）vs 目標最低需求
- 每個 cluster 是否已 **vLCM image** 化（FAIL = 仍是 baseline，須先轉換）
- **ELM** 是否啟用（VCF 9 須停用）
- **DVS** 版本（WARN，請對照目標版本）
- **備份** 設定狀態
- **VCF Operations / Fleet** 強制元件提醒

### 步驟 3：純 REST 盤點（選用，CI / 無 PowerCLI）

```bash
export VCF_USER='administrator@vsphere.local'; export VCF_PASS='***'
python3 ./scripts/precheck/get_vcf_inventory.py --sddc sddc-uat.lab.local --out inventory-uat.json --insecure
```

### 步驟 4：觸發 SDDC Manager 官方 precheck（唯讀健康檢查）

```bash
./scripts/precheck/trigger_sddc_official_precheck.sh --sddc sddc-uat.lab.local --insecure
# PROD：
./scripts/precheck/trigger_sddc_official_precheck.sh --sddc sddc.corp.local --prod prod --insecure
```

## 判讀 PASS / FAIL 與對應 remediation

| 項目 | FAIL/WARN 時的處置 |
|---|---|
| 元件版本不足 | 先把來源 VCF 升到官方允許的起始版本（例 5.2.x 的某修補級）。 |
| cluster 非 image | 在 ESX 升級階段前，把該 cluster 由 baseline 轉為 vLCM image。 |
| ELM 啟用 | 升級/匯入/收斂前先停用 Enhanced Linked Mode，功能由 VCF Operations 接手。 |
| DVS 版本過舊 | 依目標版本需求先升級 DVS。 |
| 備份未設定 | 設定 SDDC Manager / NSX / vCenter 備份並驗證可還原，才進入升級。 |

## 各環境注意事項

- **UAT**：先在此跑通全部腳本與判讀流程。
- **TEST**：建議 `RequireBackup=$true`，先確認備份。
- **PROD**：precheck 雖唯讀，bash 觸發腳本仍以 `--prod prod` 啟動二次確認；切勿在 PROD 直接執行任何變更腳本。

## 驗證 / 回退

本階段唯讀，無回退需求。請保留 precheck 報表與官方規劃工具 PDF 作為升級決策依據與稽核紀錄。
