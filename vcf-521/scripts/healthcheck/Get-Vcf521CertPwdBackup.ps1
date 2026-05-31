<#
.SYNOPSIS
    VCF 5.2.1 密碼 / 憑證到期與備份狀態盤點 (唯讀)。
.DESCRIPTION
    透過 SDDC Manager Public API (/v1) 盤點：
      - 受管帳號密碼到期 (GET /v1/credentials)
      - 憑證資訊與到期 (GET /v1/resource-certificates 或各 domain 憑證)
      - 備份組態與最近一次備份狀態 (GET /v1/system/backup-configuration, /v1/backups)
    協助升級前確認密碼未過期、憑證有效、且已有可用備份。
    API 路徑以官方文件為準：
      參見 https://developer.broadcom.com/xapis/vmware-cloud-foundation-api/latest/
.PARAMETER Environment
    目標環境名稱：uat | test | prod。
.PARAMETER ExpiryWarningDays
    密碼/憑證到期警示天數門檻 (預設 30)。
.EXAMPLE
    ./Get-Vcf521CertPwdBackup.ps1 -Environment prod -ExpiryWarningDays 45
.NOTES
    唯讀；不需 Invoke-VCFChange。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [int]$ExpiryWarningDays = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot/../../../lib/VCFGuardrails.psm1" -Force
Import-Module "$PSScriptRoot/../../../lib/VCFConnect.psm1"   -Force

function Invoke-VcfGet {
    param($Tok, [string]$Path)
    try { return Invoke-RestMethod -Method Get -Uri "$($Tok.BaseUri)$Path" -Headers $Tok.Header -SkipCertificateCheck }
    catch { Write-Host "  [略過] $Path：$($_.Exception.Message)" -ForegroundColor DarkYellow; return $null }
}

try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host '盤點模式：唯讀 (不會改動環境)' -ForegroundColor DarkGray
    $threshold = (Get-Date).AddDays($ExpiryWarningDays)
    $tok = Get-VCFRestToken -Environment $env -Service SDDC

    Write-Host "`n== 受管帳號密碼 (到期 < $ExpiryWarningDays 天) ==" -ForegroundColor Cyan
    $creds = (Invoke-VcfGet -Tok $tok -Path '/v1/credentials').elements
    if ($creds) {
        $soon = $creds | Where-Object {
            $_.PSObject.Properties.Name -contains 'expiryDate' -and $_.expiryDate -and ([datetime]$_.expiryDate -lt $threshold)
        }
        if ($soon) {
            $soon | Select-Object @{n='resource';e={$_.resource.resourceName}}, username, accountType, expiryDate |
                Format-Table -AutoSize | Out-Host
            Write-Host "  [警告] 有 $($soon.Count) 組密碼即將/已到期。" -ForegroundColor Yellow
        } else { Write-Host '  [OK] 無即將到期密碼。' -ForegroundColor Green }
    }

    Write-Host '== 資源憑證 ==' -ForegroundColor Cyan
    $domains = (Invoke-VcfGet -Tok $tok -Path '/v1/domains').elements
    foreach ($d in $domains) {
        $certs = (Invoke-VcfGet -Tok $tok -Path "/v1/domains/$($d.id)/resource-certificates").elements
        if ($certs) {
            $expSoon = $certs | Where-Object { $_.notAfter -and ([datetime]$_.notAfter -lt $threshold) }
            if ($expSoon) {
                Write-Host "  Domain $($d.name): $($expSoon.Count) 張憑證即將到期" -ForegroundColor Yellow
                $expSoon | Select-Object resourceFqdn, issuedBy, notAfter | Format-Table -AutoSize | Out-Host
            } else {
                Write-Host "  Domain $($d.name): 憑證皆有效" -ForegroundColor Green
            }
        }
    }

    Write-Host '== 備份狀態 ==' -ForegroundColor Cyan
    $bkpCfg = Invoke-VcfGet -Tok $tok -Path '/v1/system/backup-configuration'
    if ($bkpCfg) {
        $bkpCfg | ConvertTo-Json -Depth 3 | Out-Host
    }
    $bkps = Invoke-VcfGet -Tok $tok -Path '/v1/backups'
    if ($bkps -and $bkps.elements) {
        $bkps.elements | Select-Object -First 5 |
            Select-Object id, status, @{n='time';e={$_.creationTimestamp}} |
            Format-Table -AutoSize | Out-Host
        $lastOk = $bkps.elements | Where-Object { $_.status -eq 'SUCCESSFUL' } | Select-Object -First 1
        if (-not $lastOk) { Write-Host '  [警告] 找不到成功的備份紀錄！升級前請先建立可用備份。' -ForegroundColor Yellow }
        else { Write-Host '  [OK] 有成功的備份紀錄。' -ForegroundColor Green }
    } else {
        Write-Host '  [警告] 無法取得備份清單，請確認 SDDC Manager 備份已設定。' -ForegroundColor Yellow
    }

    Write-Host "`n盤點完成。" -ForegroundColor Green
}
catch {
    Write-Error "盤點失敗：$($_.Exception.Message)"
    throw
}
