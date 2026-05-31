<#
.SYNOPSIS
    VCD 升級前 precheck (唯讀)：cell 盤點、版本/build、API 版本相容、外部 DB 與
    必要前置條件檢查，輸出可貼進變更單的盤點摘要。
.DESCRIPTION
    純唯讀 (只發 GET)，不改動環境，符合「precheck=唯讀」硬性規則。

    檢查項目：
      1. Cell 清單與作用狀態 (/api/query?type=cell)。
      2. 目前 VCD 版本 / build 與支援的 API 版本 (/api/versions、product version)。
      3. 外部資料庫提示：VCD 10.6 起需 PostgreSQL 13+；本腳本無法直接連 DB，
         僅輸出檢查項提醒運維手動確認 (DB 連線資訊不在 VCD API 範圍)。
      4. 升級相容性提示：對照目標版本，列出需人工確認的相容性矩陣項目。

    所有版本/相容資訊「以官方 Release Notes / Interop Matrix 為準」：
      https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director.html
.PARAMETER Environment
    uat | test | prod。
.PARAMETER TargetVersion
    目標 VCD 版本字串 (僅用於報表標示與提醒，不做線上驗證)。
.EXAMPLE
    ./Test-VcdUpgradeReadiness.ps1 -Environment uat -TargetVersion '10.6.1.2'
.NOTES
    REST 路徑以官方 VMware Cloud Director Programming Guide / OpenAPI 為準。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [string]$TargetVersion = '10.6.1.2',
    [string]$ApiVersion = '38.1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
Import-Module (Join-Path $repoRoot 'lib/VCFGuardrails.psm1') -Force
Import-Module (Join-Path $repoRoot 'lib/VCFConnect.psm1')   -Force
Import-Module (Join-Path $PSScriptRoot '../lib/VCDApi.psm1') -Force

$pass = @()
$warn = @()
function Add-Pass { param($m) $script:pass += $m; Write-Host "  [OK] $m" -ForegroundColor Green }
function Add-Warn { param($m) $script:warn += $m; Write-Warning $m }

$conn = $null
try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host "目標版本: $TargetVersion (相容性以官方 Interop Matrix 為準)`n" -ForegroundColor White
    $conn = Connect-VcdApi -Environment $env -ApiVersion $ApiVersion

    # 1) Cell 盤點
    Write-Host '=== 1. Cell 盤點 ===' -ForegroundColor Cyan
    try {
        $cells = @((Invoke-VcdApi -Conn $conn -Path '/api/query?type=cell&format=records').record)
        if ($cells.Count -eq 0) { Add-Warn 'Cell 查詢回傳空白；請確認權限或以 VAMI/SSH 手動確認 cell 數。' }
        else {
            $cells | Select-Object name, isActive, primaryIp | Format-Table -AutoSize | Out-Host
            $inactive = @($cells | Where-Object { -not $_.isActive })
            if ($inactive) { Add-Warn ("發現 {0} 個非作用中 cell；升級前應確認叢集健康。" -f $inactive.Count) }
            else { Add-Pass ("所有 {0} 個 cell 皆作用中。" -f $cells.Count) }
        }
    }
    catch { Add-Warn "Cell 查詢失敗：$($_.Exception.Message)" }

    # 2) 版本 / API 相容
    Write-Host "`n=== 2. 版本與 API 相容 ===" -ForegroundColor Cyan
    $versions = Invoke-VcdApi -Conn $conn -Path '/api/versions'
    $supported = @($versions.versionInfo | ForEach-Object { $_.version })
    Write-Host ("目前支援 API 版本: {0}" -f ($supported -join ', '))
    if ($supported -contains $ApiVersion) { Add-Pass "協商版本 $ApiVersion 受支援。" }
    else { Add-Warn "協商版本 $ApiVersion 不在支援清單；請改用清單內版本。" }

    # 3) 外部 DB 提醒 (無法由 VCD API 直接確認)
    Write-Host "`n=== 3. 外部資料庫 ===" -ForegroundColor Cyan
    Add-Warn 'VCD 10.6+ 需 PostgreSQL 13 或更新版本。請於 DB 主機手動確認版本與備份。VCD API 無此資訊。'

    # 4) 升級前人工確認清單
    Write-Host "`n=== 4. 升級前人工確認清單 (對照官方 Release Notes) ===" -ForegroundColor Cyan
    @(
        '已建立全部 cell 的快照 / 備份，且 NFS transfer share 已備份。',
        '已備份外部 PostgreSQL 資料庫並驗證可還原。',
        "目標版本 $TargetVersion 與底層 vCenter / NSX / Avi 版本相容 (查 Interop Matrix)。",
        '已停止租戶高風險作業並公告維護視窗。',
        '已下載對應 .upgrade bundle 並核對 checksum。'
    ) | ForEach-Object { Write-Host "  [ ] $_" -ForegroundColor Yellow }

    # 摘要
    Write-Host "`n=== Precheck 摘要 ===" -ForegroundColor Cyan
    Write-Host ("通過: {0}  警告: {1}" -f $pass.Count, $warn.Count)
    if ($warn.Count -gt 0) {
        Write-Host '存在警告項，升級前請逐項排除或於變更單註記。' -ForegroundColor Yellow
        exit 2
    }
    Write-Host '基本 precheck 通過 (仍須完成人工確認清單)。' -ForegroundColor Green
}
catch {
    Write-Error "Precheck 失敗：$($_.Exception.Message)"
    exit 1
}
finally {
    if ($conn) { Disconnect-VcdApi -Conn $conn }
}
