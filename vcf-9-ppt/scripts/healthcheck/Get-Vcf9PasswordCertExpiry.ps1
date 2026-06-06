<#
.SYNOPSIS
    VCF 9 唯讀檢查：SDDC Manager 管理的帳密與憑證到期狀況。

.DESCRIPTION
    純唯讀 (ReadOnly)。透過 SDDC Manager Credentials / Certificates API 盤點：
      - 各元件帳密 (vCenter / NSX / ESX / SDDC Manager 等) 的最後輪替時間
      - 各資源憑證的到期日，並依 -WarnDays 標記即將到期者
    不會輪替密碼、不會更換憑證 (那屬於 change 範疇)。
    REST 路徑以官方 API 文件為準：https://developer.broadcom.com/xapis

.PARAMETER Environment
    uat | test | prod

.PARAMETER WarnDays
    憑證距到期日小於此天數即標記為警告，預設 30。

.EXAMPLE
    ./Get-Vcf9PasswordCertExpiry.ps1 -Environment prod -WarnDays 45

.NOTES
    安全分級：ReadOnly。可直接於 PROD 執行。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat', 'test', 'prod')][string]$Environment,
    [int]$WarnDays = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$libRoot = Join-Path $PSScriptRoot '..\..\..\lib'
Import-Module (Join-Path $libRoot 'VCFGuardrails.psm1') -Force
Import-Module (Join-Path $libRoot 'VCFConnect.psm1') -Force

try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host '[健檢] 密碼/憑證到期盤點 = ReadOnly' -ForegroundColor Green

    $sddc = Get-VCFRestToken -Environment $env -Service SDDC
    $hdr = $sddc.Header
    $base = $sddc.BaseUri

    function Invoke-SddcGet { param([string]$Path)
        Invoke-RestMethod -Method Get -Uri "$base$Path" -Headers $hdr -SkipCertificateCheck -ErrorAction Stop
    }

    # --- 帳密盤點 ---
    Write-Host "`n== Credentials (帳密) ==" -ForegroundColor Cyan
    try {
        $creds = Invoke-SddcGet -Path '/v1/credentials'
        $creds.elements | Select-Object `
        @{N = 'Resource'; E = { $_.resource.resourceName } },
        @{N = 'Type'; E = { $_.resource.resourceType } },
        username, credentialType, accountType,
        @{N = 'LastRotated'; E = { if ($_.PSObject.Properties.Name -contains 'modificationTimestamp') { $_.modificationTimestamp } else { '' } } } |
        Sort-Object Resource | Format-Table -AutoSize | Out-Host
    } catch {
        Write-Warning "Credentials 查詢失敗 (以官方 API 為準)：$($_.Exception.Message)"
    }

    # --- 憑證到期盤點 (逐 domain 查) ---
    Write-Host "`n== Certificates (憑證到期) ==" -ForegroundColor Cyan
    $now = Get-Date
    $domains = Invoke-SddcGet -Path '/v1/domains'
    $rows = foreach ($d in $domains.elements) {
        try {
            # /v1/domains/{id}/certificates  ── 路徑以官方 API 文件為準
            $certs = Invoke-SddcGet -Path "/v1/domains/$($d.id)/certificates"
            foreach ($c in $certs.elements) {
                $exp = $null
                if ($c.PSObject.Properties.Name -contains 'notAfter') {
                    [datetime]::TryParse($c.notAfter, [ref]$exp) | Out-Null
                }
                $daysLeft = if ($exp) { [int]($exp - $now).TotalDays } else { $null }
                [pscustomobject]@{
                    Domain   = $d.name
                    Resource = $c.issuedTo
                    NotAfter = $c.notAfter
                    DaysLeft = $daysLeft
                    Flag     = if ($null -ne $daysLeft -and $daysLeft -lt $WarnDays) { "⚠ <$WarnDays 天" } else { 'OK' }
                }
            }
        } catch {
            Write-Warning "Domain $($d.name) 憑證查詢失敗：$($_.Exception.Message)"
        }
    }
    if ($rows) {
        $rows | Sort-Object DaysLeft | Format-Table -AutoSize | Out-Host
        $warn = $rows | Where-Object { $_.Flag -ne 'OK' }
        if ($warn) {
            Write-Host "`n⚠ 即將到期憑證：$($warn.Count) 筆，請安排輪替 (change 流程)。" -ForegroundColor Yellow
        } else {
            Write-Host "`n所有憑證距到期皆 ≥ $WarnDays 天。" -ForegroundColor Green
        }
    }

    Write-Host "`n✓ 密碼/憑證盤點完成 (ReadOnly)。" -ForegroundColor Green
}
catch {
    Write-Error "盤點中止：$($_.Exception.Message)"
    throw
}
