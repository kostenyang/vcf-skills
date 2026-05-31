<#
.SYNOPSIS
    VCF 9 升級/擴充前盤點 (precheck，唯讀)：元件版本對照、可用 upgradables、cluster 是否 vLCM image、容量與告警。

.DESCRIPTION
    純唯讀 (ReadOnly)，不觸發任何升級或下載。盤點：
      1. 目前 VCF 版本與目標 release 的可升級性 (/v1/releases、/v1/upgradables)
      2. 各 cluster 是否已採 vLCM image-based (VCF 9 必要)
      3. 各 cluster vSAN 容量與使用率 (PowerCLI，判斷升級緩衝)
      4. 目前 CRITICAL/WARNING 告警 (升級前應清零)
      5. (選用) 觸發官方 precheck 任務的查詢 — 本腳本僅『讀取』既有 precheck 結果，
         不主動建立。實際建立 precheck 屬 change，請見 change/ 目錄與 runbook。
    REST 路徑以官方 API 文件為準：https://developer.broadcom.com/xapis

.PARAMETER Environment
    uat | test | prod

.PARAMETER TargetVersion
    目標 VCF 版本字串 (例如 '9.1.0.0')，用於比對 upgradables；選填。

.PARAMETER SkipPowerCLI
    僅 REST 盤點，不連 vCenter。

.EXAMPLE
    ./Invoke-Vcf9UpgradePrecheck.ps1 -Environment test -TargetVersion '9.1.0.0'

.NOTES
    安全分級：ReadOnly。可直接於 PROD 執行 (僅讀取)。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat', 'test', 'prod')][string]$Environment,
    [string]$TargetVersion,
    [switch]$SkipPowerCLI
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$libRoot = Join-Path $PSScriptRoot '..\..\..\lib'
Import-Module (Join-Path $libRoot 'VCFGuardrails.psm1') -Force
Import-Module (Join-Path $libRoot 'VCFConnect.psm1') -Force

$connectedVc = $false
try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host '[Precheck] 升級/擴充前盤點 = ReadOnly (不觸發升級)' -ForegroundColor Green

    $sddc = Get-VCFRestToken -Environment $env -Service SDDC
    $hdr = $sddc.Header; $base = $sddc.BaseUri
    function Invoke-SddcGet { param([string]$Path)
        Invoke-RestMethod -Method Get -Uri "$base$Path" -Headers $hdr -SkipCertificateCheck -ErrorAction Stop
    }

    # 1) 目前版本
    Write-Host "`n== 目前 VCF / SDDC Manager 版本 ==" -ForegroundColor Cyan
    try {
        (Invoke-SddcGet -Path '/v1/sddc-managers').elements |
        Select-Object fqdn, version | Format-Table -AutoSize | Out-Host
    } catch { Write-Warning "版本查詢失敗：$($_.Exception.Message)" }

    # 2) 可升級目標 (releases / upgradables)
    Write-Host "`n== 可用升級目標 (upgradables) ==" -ForegroundColor Cyan
    try {
        $up = Invoke-SddcGet -Path '/v1/upgradables'
        $rows = $up.elements | Select-Object @{N = 'Bundle'; E = { $_.bundleId } }, version, status,
        @{N = 'Applicable'; E = { $_.applicabilityStatus } }
        if ($rows) { $rows | Format-Table -AutoSize | Out-Host }
        else { Write-Host '目前無可套用之 upgradable。' -ForegroundColor DarkGray }

        if ($TargetVersion) {
            $hit = $rows | Where-Object { "$($_.version)" -like "*$TargetVersion*" }
            if ($hit) { Write-Host "✓ 找到目標版本 $TargetVersion 的 upgradable。" -ForegroundColor Green }
            else { Write-Host "⚠ 未找到目標版本 $TargetVersion，可能需先下載 bundle 或目前路徑不支援。" -ForegroundColor Yellow }
        }
    } catch {
        Write-Warning "upgradables 查詢失敗 (端點以官方 API 為準)：$($_.Exception.Message)"
    }

    # 3) Cluster 是否 image-based
    Write-Host "`n== Cluster vLCM image-based 檢查 (VCF 9 必要) ==" -ForegroundColor Cyan
    $clusters = (Invoke-SddcGet -Path '/v1/clusters').elements
    foreach ($c in $clusters) {
        $img = if ($c.PSObject.Properties.Name -contains 'isImageBased') { $c.isImageBased } else { '未知(查API)' }
        $mark = if ($img -eq $true) { '✓' } elseif ($img -eq $false) { '✗ 需轉 image' } else { '?' }
        Write-Host ("  {0,-30} imageBased={1} {2}" -f $c.name, $img, $mark)
    }

    # 4) 告警 (升級前應清零)
    Write-Host "`n== 升級前告警檢查 ==" -ForegroundColor Cyan
    try {
        $alerts = (Invoke-SddcGet -Path '/v1/system/alerts').elements |
        Where-Object { $_.severity -in @('CRITICAL', 'WARNING') }
        if ($alerts) {
            Write-Host "⚠ 仍有 $($alerts.Count) 筆 CRITICAL/WARNING 告警，升級前建議清零：" -ForegroundColor Yellow
            $alerts | Select-Object severity, message | Format-Table -AutoSize | Out-Host
        } else { Write-Host '✓ 無 CRITICAL/WARNING 告警。' -ForegroundColor Green }
    } catch { Write-Warning "告警查詢失敗：$($_.Exception.Message)" }

    # 5) vSAN 容量緩衝 (PowerCLI)
    if (-not $SkipPowerCLI) {
        Write-Host "`n== vSAN 容量緩衝 (升級需保留 slack space) ==" -ForegroundColor Cyan
        try {
            Connect-VCFvCenter -Environment $env -AllLinked | Out-Null
            $connectedVc = $true
            foreach ($cl in Get-Cluster) {
                $ds = Get-Datastore -RelatedObject $cl -ErrorAction SilentlyContinue |
                Where-Object { $_.Type -eq 'vsan' }
                foreach ($d in $ds) {
                    $usedPct = if ($d.CapacityGB -gt 0) {
                        [math]::Round((($d.CapacityGB - $d.FreeSpaceGB) / $d.CapacityGB) * 100, 1)
                    } else { 0 }
                    $flag = if ($usedPct -ge 70) { '⚠ 偏高' } else { 'OK' }
                    Write-Host ("  {0,-25} {1,-20} 使用 {2}% (Cap={3}GB Free={4}GB) {5}" -f `
                            $cl.Name, $d.Name, $usedPct, [int]$d.CapacityGB, [int]$d.FreeSpaceGB, $flag)
                }
            }
        } catch { Write-Warning "vSAN 容量查詢失敗：$($_.Exception.Message)" }
    }

    Write-Host "`n✓ Precheck 完成 (ReadOnly)。請依結果決定是否進入 change 流程。" -ForegroundColor Green
}
catch {
    Write-Error "Precheck 中止：$($_.Exception.Message)"
    throw
}
finally {
    if ($connectedVc) { Disconnect-VCFAll }
}
