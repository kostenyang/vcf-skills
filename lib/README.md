# lib/ — VCF 操作共用框架

這是所有「實戰操作型」腳本的共用地基：**環境分級 (UAT/TEST/PROD)**、**安全護欄**、
**連線與認證**。每個 skill 的 `scripts/` 都應該載入並使用這套框架，不要各自硬寫連線與密碼。

## 檔案

| 檔案 | 用途 |
|------|------|
| `environments.example.psd1` | 環境清單範本。複製成 `environments.psd1` 填你的環境（後者不入 git） |
| `VCFGuardrails.psm1` | 安全護欄：`Get-VCFEnvironment`、`Invoke-VCFChange`（依 Tier 分級確認） |
| `VCFConnect.psm1` | 連線：`Connect-VCFvCenter`、`Get-VCFRestToken`（SDDC/NSX/HCX）、`Get-VCFCredential` |

## 先決條件

```powershell
Install-Module VMware.PowerCLI -Scope CurrentUser
Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore -Scope CurrentUser
# PowerCLI 憑證/CEIP 設定（自簽憑證環境）
Set-PowerCLIConfiguration -InvalidCertificateAction Prompt -Participate $false -Confirm:$false
```

## 認證（絕不存明文密碼）

用 SecretManagement 存每個環境的 PSCredential，名稱對應 `environments.psd1` 的 `CredentialName`：

```powershell
# 一次性設定 vault
Register-SecretVault -Name VCF -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

# 為各環境存帳密 (互動輸入，不落地明文)
Set-Secret -Name vcf-uat  -Secret (Get-Credential)
Set-Secret -Name vcf-test -Secret (Get-Credential)
Set-Secret -Name vcf-prod -Secret (Get-Credential)
```

## 安全分級（核心）

| Tier | 變更行為 |
|------|----------|
| **UAT**  | 允許變更，單次 `[y/N]` 確認 |
| **TEST** | 允許變更，單次確認；建議先備份 |
| **PROD** | **預設禁止**；變更需 `-ForceProdChange` + 變更單號 + 確認已備份 + 輸入完整環境名二次確認；破壞性操作再輸入 `DESTROY`；且一律先 dry-run 預覽 |

## 標準用法

```powershell
Import-Module ./lib/VCFGuardrails.psm1 -Force
Import-Module ./lib/VCFConnect.psm1   -Force

$env = Get-VCFEnvironment -Name uat          # 讀環境 + Tier

# 唯讀：直接做
$vc = Connect-VCFvCenter -Environment $env
Get-VMHost | Select Name, ConnectionState, Version

# 變更：一律走護欄
Invoke-VCFChange -Environment $env -Description "進入維護模式 esx01" -Impact Change `
    -Preview { "esx01 → MaintenanceMode (evacuate)" } `
    -Action  { Set-VMHost -VMHost esx01 -State Maintenance -Evacuate }

Disconnect-VCFAll
```

PROD 範例（提權 + 單號）：

```powershell
$prod = Get-VCFEnvironment -Name prod
Invoke-VCFChange -Environment $prod -Description "套用 NSX 升級 bundle" -Impact Change `
    -ForceProdChange -ChangeTicket "CHG0012345" `
    -Preview { "將套用 bundle xxx 到 nsx prod" } `
    -Action  { <# 實際 REST/PowerCLI 呼叫 #> }
```

## 紅線

- **正式環境（PROD）一律先在 UAT/TEST 驗證腳本**，再以護欄執行。
- 所有腳本預設唯讀；任何寫入都必須經 `Invoke-VCFChange`。
- 版本、API、相容性以 Broadcom 官方文件為準；腳本僅為自動化輔助，不取代人工判斷。
- 非 PowerShell 的場景（Python / REST / govc）也遵循同樣的「先預覽、PROD 二次確認、先測試環境」原則。
