<#
.SYNOPSIS
    VCF 5.2.1 Workload Domain / Cluster / Host 健康狀態盤點 (唯讀)。
.DESCRIPTION
    透過 SDDC Manager Public API (/v1) 列出所有 Domain (Management / VI)、
    各 Domain 的 Cluster、Host 與 vSAN 狀態；並可選擇以 PowerCLI 連 vCenter
    交叉比對 Host 連線/維護模式。本腳本為『唯讀』，不會改動任何環境。
    API 路徑以官方文件為準：
      GET /v1/domains, GET /v1/clusters, GET /v1/hosts
      參見 https://developer.broadcom.com/xapis/vmware-cloud-foundation-api/latest/
.PARAMETER Environment
    目標環境名稱：uat | test | prod。
.PARAMETER IncludeVCenter
    額外以 PowerCLI 連 vCenter 交叉比對 ESXi 狀態。
.EXAMPLE
    ./Get-Vcf521DomainHealth.ps1 -Environment uat
.EXAMPLE
    ./Get-Vcf521DomainHealth.ps1 -Environment prod -IncludeVCenter
.NOTES
    唯讀；不需 Invoke-VCFChange。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [switch]$IncludeVCenter
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot/../../../lib/VCFGuardrails.psm1" -Force
Import-Module "$PSScriptRoot/../../../lib/VCFConnect.psm1"   -Force

$connectedVc = $false
try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host '健檢模式：唯讀 (不會改動環境)' -ForegroundColor DarkGray

    $tok = Get-VCFRestToken -Environment $env -Service SDDC

    Write-Host "`n== Workload Domains ==" -ForegroundColor Cyan
    $domains = (Invoke-RestMethod -Method Get -Uri "$($tok.BaseUri)/v1/domains" -Headers $tok.Header -SkipCertificateCheck).elements
    $domains |
        Select-Object name, type,
            @{n='status';e={$_.status}},
            @{n='clusters';e={ if ($_.clusters) { $_.clusters.Count } else { 0 } }} |
        Format-Table -AutoSize | Out-Host

    Write-Host '== Clusters ==' -ForegroundColor Cyan
    $clusters = (Invoke-RestMethod -Method Get -Uri "$($tok.BaseUri)/v1/clusters" -Headers $tok.Header -SkipCertificateCheck).elements
    $clusters |
        Select-Object name,
            @{n='primaryDatastoreType';e={$_.primaryDatastoreType}},
            @{n='status';e={$_.status}},
            @{n='isStretched';e={$_.isStretched}},
            @{n='hosts';e={ if ($_.hosts) { $_.hosts.Count } else { 0 } }} |
        Format-Table -AutoSize | Out-Host

    Write-Host '== Hosts (SDDC Manager 視角) ==' -ForegroundColor Cyan
    $hosts = (Invoke-RestMethod -Method Get -Uri "$($tok.BaseUri)/v1/hosts" -Headers $tok.Header -SkipCertificateCheck).elements
    $hosts |
        Select-Object fqdn,
            @{n='status';e={$_.status}},
            @{n='esxiVersion';e={$_.esxiVersion}},
            @{n='domain';e={$_.domain.name}} |
        Sort-Object domain, fqdn | Format-Table -AutoSize | Out-Host

    $unhealthy = $hosts | Where-Object { $_.status -and $_.status -ne 'ASSIGNED' -and $_.status -ne 'ACTIVE' }
    if ($unhealthy) {
        Write-Host "[警告] 有 $($unhealthy.Count) 台 host 狀態非正常，請複查。" -ForegroundColor Yellow
    } else {
        Write-Host '[OK] 所有 host 狀態正常。' -ForegroundColor Green
    }

    if ($IncludeVCenter) {
        Write-Host "`n== vCenter 交叉比對 (PowerCLI) ==" -ForegroundColor Cyan
        Connect-VCFvCenter -Environment $env -AllLinked | Out-Null
        $connectedVc = $true
        Get-VMHost |
            Select-Object Name, ConnectionState, PowerState,
                @{n='Maintenance';e={$_.ConnectionState -eq 'Maintenance'}},
                Version, Build |
            Sort-Object Name | Format-Table -AutoSize | Out-Host
    }

    Write-Host "`n健檢完成。" -ForegroundColor Green
}
catch {
    Write-Error "健檢失敗：$($_.Exception.Message)"
    throw
}
finally {
    if ($connectedVc) { Disconnect-VCFAll }
}
