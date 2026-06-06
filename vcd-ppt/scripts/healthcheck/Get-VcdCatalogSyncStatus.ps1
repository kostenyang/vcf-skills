<#
.SYNOPSIS
    VCD 唯讀健檢：Catalog 與內 catalog item 的同步狀態 (subscribed / published catalog)。
.DESCRIPTION
    純唯讀 (只發 GET)。列出所有 catalog，標示是否為 subscribed/published，並查詢
    其 catalog items 的同步/匯入狀態，協助發現「散布卡住 / 同步失敗」的內容庫。

    使用 legacy query：
      /api/query?type=catalog
      /api/query?type=adminCatalogItem  (以官方 API 文件為準)
    部分新欄位亦可由 /cloudapi/1.0.0 取得；此處用 query 服務涵蓋面較廣。
.PARAMETER Environment
    uat | test | prod。
.EXAMPLE
    ./Get-VcdCatalogSyncStatus.ps1 -Environment test
.NOTES
    REST 路徑以官方 VMware Cloud Director Programming Guide / OpenAPI 為準。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [string]$ApiVersion = '38.1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
Import-Module (Join-Path $repoRoot 'lib/VCFGuardrails.psm1') -Force
Import-Module (Join-Path $repoRoot 'lib/VCFConnect.psm1')   -Force
Import-Module (Join-Path $PSScriptRoot '../lib/VCDApi.psm1') -Force

$conn = $null
try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    $conn = Connect-VcdApi -Environment $env -ApiVersion $ApiVersion

    Write-Host "`n=== Catalog 清單 ===" -ForegroundColor Cyan
    $cats = Invoke-VcdApi -Conn $conn -Path '/api/query?type=catalog&format=records'
    $catRecords = @($cats.record)
    if (-not $catRecords) { Write-Host '(查無 catalog)' -ForegroundColor DarkGray }
    else {
        $catRecords |
            Select-Object name, orgName, isPublished, isShared, numberOfVAppTemplates, numberOfMedia |
            Format-Table -AutoSize | Out-Host
    }

    Write-Host "`n=== Catalog Item 同步狀態 ===" -ForegroundColor Cyan
    try {
        $items = Invoke-VcdApi -Conn $conn -Path '/api/query?type=adminCatalogItem&format=records'
        $itemRecords = @($items.record)
        # 標示尚在同步 / 失敗的項目 (status 欄位以官方 API 文件為準)
        $problems = $itemRecords | Where-Object {
            $_.PSObject.Properties.Name -contains 'status' -and $_.status -notin @('RESOLVED','READY','POWERED_OFF', $null)
        }
        Write-Host ("Catalog item 總數: {0}" -f $itemRecords.Count)
        if ($problems) {
            Write-Warning ("發現 {0} 個非就緒項目：" -f @($problems).Count)
            @($problems) | Select-Object name, catalogName, status | Format-Table -AutoSize | Out-Host
        } else {
            Write-Host '所有 catalog item 皆為就緒狀態。' -ForegroundColor Green
        }
    }
    catch { Write-Warning "Catalog item 查詢失敗：$($_.Exception.Message)" }

    Write-Host "`nCatalog 同步健檢完成 (唯讀)。" -ForegroundColor Green
}
catch {
    Write-Error "Catalog 健檢失敗：$($_.Exception.Message)"
    exit 1
}
finally {
    if ($conn) { Disconnect-VcdApi -Conn $conn }
}
