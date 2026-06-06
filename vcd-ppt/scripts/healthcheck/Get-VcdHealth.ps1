<#
.SYNOPSIS
    VMware Cloud Director (VCD) 唯讀健檢：cell 狀態、版本、Provider/Org/OrgVDC 清單與
    配額用量、Edge Gateway 狀態總覽。
.DESCRIPTION
    純唯讀 (只發 GET)，不改動任何環境，符合「健檢=唯讀」硬性規則。
    連線與憑證一律走 lib/ 框架 (Get-VCFEnvironment / Get-VCFCredential) 與
    scripts/lib/VCDApi.psm1，不寫死 IP/密碼。

    涵蓋：
      1. /api/versions          — 支援的 API 版本 (確認相容性)
      2. /api/query?type=cell   — Cell 清單與狀態 (legacy admin query；以官方 API 文件為準)
      3. /cloudapi/1.0.0/orgs   — Organization 清單
      4. /cloudapi/1.0.0/orgVdcs— Org VDC 清單 + 配額/用量
      5. /cloudapi/1.0.0/edgeGateways — Edge Gateway 清單與狀態
.PARAMETER Environment
    uat | test | prod，由 Get-VCFEnvironment 解析。
.PARAMETER ApiVersion
    協商的 VCD API 版本，預設 38.1 (VCD 10.6.x)。
.PARAMETER OutputJson
    若指定，將完整結果寫成 JSON 檔。
.EXAMPLE
    ./Get-VcdHealth.ps1 -Environment uat
.EXAMPLE
    ./Get-VcdHealth.ps1 -Environment prod -OutputJson ./vcd-prod-health.json
.NOTES
    REST 路徑以官方 VMware Cloud Director OpenAPI / Programming Guide 為準。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [string]$ApiVersion = '38.1',
    [string]$OutputJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
Import-Module (Join-Path $repoRoot 'lib/VCFGuardrails.psm1') -Force
Import-Module (Join-Path $repoRoot 'lib/VCFConnect.psm1')   -Force
Import-Module (Join-Path $PSScriptRoot '../lib/VCDApi.psm1') -Force

function Write-Section { param([string]$T) Write-Host "`n=== $T ===" -ForegroundColor Cyan }

$conn = $null
try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    $conn = Connect-VcdApi -Environment $env -ApiVersion $ApiVersion

    $report = [ordered]@{
        Environment = $env.Name
        Tier        = $env.Tier
        VcdHost     = $conn.Host
        CheckedAt   = (Get-Date).ToString('s')
    }

    # 1) API 版本相容性
    Write-Section 'API 版本'
    $versions = Invoke-VcdApi -Conn $conn -Path '/api/versions'
    $supported = @($versions.versionInfo | ForEach-Object { $_.version })
    Write-Host ("支援版本: {0}" -f ($supported -join ', '))
    $report.SupportedApiVersions = $supported

    # 2) Cell 狀態 (legacy admin query；不同版本欄位可能不同，以官方 API 文件為準)
    Write-Section 'Cell 狀態'
    try {
        $cells = Invoke-VcdApi -Conn $conn -Path '/api/query?type=cell&format=records'
        $cellRecords = @($cells.record)
        if ($cellRecords) {
            $cellRecords | Select-Object name, isActive, primaryIp, productBuildDate |
                Format-Table -AutoSize | Out-Host
        } else { Write-Host '(查無 cell 記錄)' -ForegroundColor DarkGray }
        $report.Cells = $cellRecords | Select-Object name, isActive, primaryIp
    }
    catch { Write-Warning "Cell 查詢失敗 (可能授權或版本差異)：$($_.Exception.Message)" }

    # 3) Organizations
    Write-Section 'Organizations'
    $orgs = Get-VcdPagedResult -Conn $conn -Path '/cloudapi/1.0.0/orgs'
    Write-Host ("Org 數量: {0}" -f @($orgs).Count)
    @($orgs) | Select-Object name, displayName, isEnabled | Format-Table -AutoSize | Out-Host
    $report.OrgCount = @($orgs).Count
    $report.Orgs = @($orgs) | Select-Object name, displayName, isEnabled

    # 4) Org VDC 配額/用量
    Write-Section 'Org VDC 配額與用量'
    $vdcs = Get-VcdPagedResult -Conn $conn -Path '/cloudapi/1.0.0/orgVdcs'
    Write-Host ("Org VDC 數量: {0}" -f @($vdcs).Count)
    @($vdcs) |
        Select-Object name, @{n='org';e={$_.orgRef.name}}, allocationModel, isEnabled |
        Format-Table -AutoSize | Out-Host
    $report.OrgVdcCount = @($vdcs).Count
    $report.OrgVdcs = @($vdcs) | Select-Object name, allocationModel, isEnabled

    # 5) Edge Gateways
    Write-Section 'Edge Gateways'
    $edges = Get-VcdPagedResult -Conn $conn -Path '/cloudapi/1.0.0/edgeGateways'
    Write-Host ("Edge Gateway 數量: {0}" -f @($edges).Count)
    @($edges) |
        Select-Object name, @{n='ownerVdc';e={$_.orgVdc.name}}, @{n='status';e={$_.status}} |
        Format-Table -AutoSize | Out-Host
    $report.EdgeGatewayCount = @($edges).Count

    if ($OutputJson) {
        $report | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputJson -Encoding utf8
        Write-Host "`n已輸出 JSON: $OutputJson" -ForegroundColor Green
    }
    Write-Host "`n健檢完成 (唯讀)。" -ForegroundColor Green
}
catch {
    Write-Error "VCD 健檢失敗：$($_.Exception.Message)"
    exit 1
}
finally {
    if ($conn) { Disconnect-VcdApi -Conn $conn }
    # 本腳本未連 vCenter (PowerCLI)，故無需 Disconnect-VCFAll；如後續擴充再加。
}
