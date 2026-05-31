<#
.SYNOPSIS
    HCX 遷移前盤點 (precheck, 唯讀)：來源 VM 清單/大小/開機狀態、需延伸網段、
    目的資源概況，並依規模估算建議並行度 (300 / 600 / 1000)。
.DESCRIPTION
    純查詢，不改動環境。
      - 來源 VM 資訊：透過 PowerCLI 連來源 vCenter 取得 (size/power/networks)。
      - HCX 端：透過 REST 列出已配對站台與既有 Network Extension，協助比對
        哪些網段尚未延伸。
    並行度建議參考 KB 373010 (HCX 4.10+ 預設 300，可調 Medium 600 / Large 1000)。
.PARAMETER Environment
    來源端 uat | test | prod。
.PARAMETER VMNamePattern
    要盤點的 VM 名稱樣式 (萬用字元)，例如 'app-*'。
.PARAMETER ConcurrencyTier
    Default(300) | Medium(600) | Large(1000)。僅作估算，不套用設定。
.EXAMPLE
    ./Get-HcxMigrationPrecheck.ps1 -Environment uat -VMNamePattern 'app-*'
.NOTES
    需先 Import-Module lib/VCFGuardrails.psm1, lib/VCFConnect.psm1。
    需 VMware.PowerCLI。並行度上限亦受 IX/NE appliance 數與頻寬限制。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$VMNamePattern,
    [ValidateSet('Default','Medium','Large')][string]$ConcurrencyTier = 'Default'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Import-Module (Join-Path $repo 'lib/VCFGuardrails.psm1') -Force
Import-Module (Join-Path $repo 'lib/VCFConnect.psm1')   -Force

try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host "HCX 遷移前盤點 (唯讀) — 來源 vCenter: $($env.vCenter)" -ForegroundColor Cyan

    # ---- 來源 VM 盤點 (PowerCLI) ----
    Connect-VCFvCenter -Environment $env | Out-Null

    $vms = Get-VM -Name $VMNamePattern -ErrorAction Stop
    if (-not $vms) { throw "找不到符合 '$VMNamePattern' 的 VM。" }

    Write-Host "`n=== 來源 VM 清單 ===" -ForegroundColor Green
    $report = foreach ($vm in $vms) {
        $nets = @($vm | Get-NetworkAdapter | Select-Object -ExpandProperty NetworkName -Unique)
        [pscustomobject]@{
            Name        = $vm.Name
            PowerState  = $vm.PowerState
            vCPU        = $vm.NumCpu
            MemoryGB    = $vm.MemoryGB
            UsedSpaceGB = [math]::Round($vm.UsedSpaceGB, 1)
            Networks    = ($nets -join ', ')
            GuestOS     = $vm.Guest.OSFullName
        }
    }
    $report | Format-Table -AutoSize | Out-Host

    $totalGB   = [math]::Round(($report | Measure-Object UsedSpaceGB -Sum).Sum, 1)
    $poweredOn = @($report | Where-Object PowerState -eq 'PoweredOn').Count
    $vmCount   = $report.Count

    # ---- 需延伸的網段 (來源網路集合) ----
    $srcNetworks = $report.Networks -split ',\s*' | Where-Object { $_ } | Select-Object -Unique | Sort-Object

    # ---- HCX 端：既有 Network Extension 比對 ----
    Write-Host "`n=== 網段延伸比對 ===" -ForegroundColor Green
    $extendedNames = @()
    try {
        $tok = Get-VCFRestToken -Environment $env -Service HCX
        $uri = "$($tok.BaseUri)/hybridity/api/l2Extensions"  # 以官方 API 文件為準
        $l2  = Invoke-RestMethod -Method GET -Uri $uri -Headers $tok.Header -ContentType 'application/json' -SkipCertificateCheck
        $extendedNames = @($l2.items.networkName)
    } catch {
        Write-Host "  (無法查詢既有 Network Extension：$($_.Exception.Message))" -ForegroundColor Yellow
    }
    foreach ($n in $srcNetworks) {
        $isExt = $extendedNames -contains $n
        $mark  = if ($isExt) { '已延伸' } else { '需建立 NE' }
        $color = if ($isExt) { 'Green' } else { 'Yellow' }
        Write-Host ("  {0,-30} {1}" -f $n, $mark) -ForegroundColor $color
    }

    # ---- 並行度估算 ----
    $cap = switch ($ConcurrencyTier) { 'Medium' {600} 'Large' {1000} default {300} }
    Write-Host "`n=== 規模 / 並行度估算 (KB 373010) ===" -ForegroundColor Green
    Write-Host ("  VM 數量        : {0}  (PoweredOn={1})" -f $vmCount, $poweredOn)
    Write-Host ("  資料總量(已用) : {0} GB" -f $totalGB)
    Write-Host ("  並行度層級     : {0}  (上限 {1} 並行 / HCX Manager)" -f $ConcurrencyTier, $cap)
    $waves = [math]::Ceiling($vmCount / [double]$cap)
    Write-Host ("  以此層級估算需 {0} 個並行批次 (波次另依切換窗 / 頻寬細分)" -f $waves)
    Write-Host "  註：實際並行受 IX/NE appliance 數與頻寬限制 (單 IX ~1.6 Gbps、單流 ~1 Gbps)。" -ForegroundColor DarkGray

    Write-Host "`n盤點完成 (唯讀，未改動環境)。" -ForegroundColor Cyan
}
catch {
    Write-Error "precheck 失敗：$($_.Exception.Message)"
    throw
}
finally {
    Disconnect-VCFAll
}
