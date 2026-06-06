<#
.SYNOPSIS
    VCF 5.2.1 SDDC Manager 服務狀態與 BOM / 版本盤點 (唯讀)。
.DESCRIPTION
    透過 SDDC Manager Public API (/v1) 取得目前 VCF 版本 (releases / system / version)
    與各元件 (vCenter / NSX / ESXi / SDDC Manager) build number，協助確認是否符合
    5.2.1 BOM；並列出 SDDC Manager 端可查詢的服務/憑證/健康摘要。
    API 路徑以官方文件為準：
      GET /v1/sddc-manager, GET /v1/system/health-summary (若可用),
      GET /v1/releases, GET /v1/manifests / /v1/bundles
      參見 https://developer.broadcom.com/xapis/vmware-cloud-foundation-api/latest/
    版號 / build 與相容性一律以 Broadcom TechDocs Release Notes 為準。
.PARAMETER Environment
    目標環境名稱：uat | test | prod。
.EXAMPLE
    ./Get-Vcf521ServiceAndBom.ps1 -Environment test
.NOTES
    唯讀；不需 Invoke-VCFChange。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot/../../../lib/VCFGuardrails.psm1" -Force
Import-Module "$PSScriptRoot/../../../lib/VCFConnect.psm1"   -Force

function Invoke-VcfGet {
    param($Tok, [string]$Path)
    try {
        return Invoke-RestMethod -Method Get -Uri "$($Tok.BaseUri)$Path" -Headers $Tok.Header -SkipCertificateCheck
    } catch {
        Write-Host "  [略過] $Path 無法取得：$($_.Exception.Message)" -ForegroundColor DarkYellow
        return $null
    }
}

try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host '盤點模式：唯讀 (不會改動環境)' -ForegroundColor DarkGray

    $tok = Get-VCFRestToken -Environment $env -Service SDDC

    Write-Host "`n== SDDC Manager ==" -ForegroundColor Cyan
    $sddc = Invoke-VcfGet -Tok $tok -Path '/v1/sddc-manager'
    if ($sddc) {
        $sddc | Select-Object id, version, fqdn | Format-List | Out-Host
    }

    Write-Host '== 目前 VCF Release / BOM ==' -ForegroundColor Cyan
    # /v1/releases?domainId=... 可取得各域目前 release 與其 BOM
    $domains = (Invoke-VcfGet -Tok $tok -Path '/v1/domains').elements
    foreach ($d in $domains) {
        Write-Host "  Domain: $($d.name) [$($d.type)]" -ForegroundColor White
        $rel = Invoke-VcfGet -Tok $tok -Path "/v1/releases?domainId=$($d.id)"
        $current = if ($rel) { $rel.elements | Select-Object -First 1 } else { $null }
        if ($current) {
            Write-Host "    Release: $($current.version)  ($($current.description))"
            if ($current.bom) {
                $current.bom |
                    Select-Object name, version |
                    Format-Table -AutoSize | Out-Host
            }
        }
    }

    Write-Host '== 健康摘要 (若 API 提供) ==' -ForegroundColor Cyan
    $health = Invoke-VcfGet -Tok $tok -Path '/v1/system/health-summary'
    if ($health) {
        $health | ConvertTo-Json -Depth 4 | Out-Host
    } else {
        Write-Host '  health-summary 不可用，建議於 SDDC Manager 跑 SoS 健康檢查 (官方工具)。' -ForegroundColor DarkGray
    }

    Write-Host "`n盤點完成。請以 Broadcom Release Notes 比對 5.2.1 BOM。" -ForegroundColor Green
}
catch {
    Write-Error "盤點失敗：$($_.Exception.Message)"
    throw
}
