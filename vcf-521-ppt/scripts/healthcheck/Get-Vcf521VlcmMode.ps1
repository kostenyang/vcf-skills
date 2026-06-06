<#
.SYNOPSIS
    VCF 5.2.1 各 Cluster 的 vLCM 模式 (baseline vs image) 盤點 (唯讀)。
.DESCRIPTION
    5.2.1 允許同一 Workload Domain 內 baseline 與 image 叢集混用，但升級到 VCF 9
    之前所有叢集必須轉為 vLCM image 模式 (且轉換功能需先升到 5.2.2)。
    本腳本以 PowerCLI 連 vCenter，盤點每個 Cluster 是否啟用 vLCM image
    (Get-Cluster ... 的 baseline/image 設定)，並標示仍為 baseline 的叢集。
    唯讀；不會改動環境。
.PARAMETER Environment
    目標環境名稱：uat | test | prod。
.EXAMPLE
    ./Get-Vcf521VlcmMode.ps1 -Environment prod
.NOTES
    判斷邏輯以 PowerCLI 物件屬性為準；不同 PowerCLI 版本屬性名可能略異，
    若取不到 image 屬性，請於 vSphere Client 確認叢集是否『使用單一映像管理』。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot/../../../lib/VCFGuardrails.psm1" -Force
Import-Module "$PSScriptRoot/../../../lib/VCFConnect.psm1"   -Force

$connected = $false
try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host '盤點模式：唯讀 (不會改動環境)' -ForegroundColor DarkGray

    Connect-VCFvCenter -Environment $env -AllLinked | Out-Null
    $connected = $true

    $results = foreach ($c in Get-Cluster) {
        # 嘗試讀取 vLCM image 設定 (使用單一映像管理)
        $isImage = $false
        try {
            $view = Get-View -Id $c.Id
            # 叢集啟用 image 時 desiredSoftwareSpec 會存在
            if ($view.ConfigurationEx -and $view.ConfigurationEx.PSObject.Properties.Name -contains 'desiredSoftwareSpec' `
                -and $null -ne $view.ConfigurationEx.desiredSoftwareSpec) {
                $isImage = $true
            }
        } catch { $isImage = $false }

        [pscustomobject]@{
            Cluster   = $c.Name
            vLCMMode  = if ($isImage) { 'image' } else { 'baseline' }
            Hosts     = $c.ExtensionData.Host.Count
            NeedConvert = (-not $isImage)
        }
    }

    $results | Sort-Object vLCMMode, Cluster | Format-Table -AutoSize | Out-Host

    $baseline = $results | Where-Object NeedConvert
    if ($baseline) {
        Write-Host "`n[注意] 以下叢集仍為 baseline，升級至 VCF 9 前須轉為 image" -ForegroundColor Yellow
        Write-Host '      (baseline->image 轉換功能需先升到 VCF 5.2.2)：' -ForegroundColor Yellow
        $baseline.Cluster | ForEach-Object { Write-Host "        - $_" -ForegroundColor Yellow }
    } else {
        Write-Host "`n[OK] 所有叢集皆為 image 模式。" -ForegroundColor Green
    }
}
catch {
    Write-Error "盤點失敗：$($_.Exception.Message)"
    throw
}
finally {
    if ($connected) { Disconnect-VCFAll }
}
