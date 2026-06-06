<#
.SYNOPSIS
    VCF 9 變更：將 ESX host 進入 / 離開維護模式 (透過 PowerCLI，包在 Invoke-VCFChange 護欄內)。

.DESCRIPTION
    這是『會改動環境』的操作，全程包在 Invoke-VCFChange：
      - 先 dry-run 預覽 (顯示目標 host、目前狀態、vSAN 資料疏散策略)
      - UAT/TEST 單次確認；PROD 需 -ForceProdChange + 變更單號 + 備份確認 + 環境名二次確認
    進入維護模式時對 vSAN 叢集採 EnsureAccessibility (預設) 以縮短時間；
    可用 -VsanDataMigration 改為 Full / NoDataMigration。

.PARAMETER Environment
    uat | test | prod

.PARAMETER VMHostName
    目標 ESX host FQDN。

.PARAMETER Action
    Enter | Exit

.PARAMETER VsanDataMigration
    進入維護模式時的 vSAN 資料疏散：EnsureAccessibility (預設) | Full | NoDataMigration

.PARAMETER Timeout
    進入維護模式逾時秒數，預設 7200。

.PARAMETER ForceProdChange
    PROD 提權旗標 (轉交 Invoke-VCFChange)。

.PARAMETER ChangeTicket
    變更單號 (PROD 必填)。

.EXAMPLE
    ./Set-Vcf9HostMaintenance.ps1 -Environment test -VMHostName esx01.corp.local -Action Enter

.EXAMPLE
    ./Set-Vcf9HostMaintenance.ps1 -Environment prod -VMHostName esx01.corp.local -Action Enter `
        -ForceProdChange -ChangeTicket CHG0012345

.NOTES
    安全分級：Change。請先在 UAT/TEST 驗證再上 PROD。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat', 'test', 'prod')][string]$Environment,
    [Parameter(Mandatory)][string]$VMHostName,
    [Parameter(Mandatory)][ValidateSet('Enter', 'Exit')][string]$Action,
    [ValidateSet('EnsureAccessibility', 'Full', 'NoDataMigration')][string]$VsanDataMigration = 'EnsureAccessibility',
    [int]$Timeout = 7200,
    [switch]$ForceProdChange,
    [string]$ChangeTicket
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$libRoot = Join-Path $PSScriptRoot '..\..\..\lib'
Import-Module (Join-Path $libRoot 'VCFGuardrails.psm1') -Force
Import-Module (Join-Path $libRoot 'VCFConnect.psm1') -Force

$connectedVc = $false
try {
    $env = Get-VCFEnvironment -Name $Environment
    Connect-VCFvCenter -Environment $env -AllLinked | Out-Null
    $connectedVc = $true

    $vmhost = Get-VMHost -Name $VMHostName -ErrorAction Stop
    $desc = "Host '$VMHostName' $Action 維護模式 (vSAN 疏散=$VsanDataMigration)"

    Invoke-VCFChange -Environment $env -Description $desc -Impact 'Change' `
        -ForceProdChange:$ForceProdChange -ChangeTicket $ChangeTicket `
        -Preview {
        "目前狀態: $($vmhost.ConnectionState) / Power=$($vmhost.PowerState)"
        "目標動作: $Action 維護模式"
        if ($Action -eq 'Enter') {
            "進入前將先檢查叢集 HA/DRS 可容納，並以 $VsanDataMigration 疏散 vSAN 資料。"
            "逾時設定: $Timeout 秒。"
        } else {
            "將使 host 退出維護模式並恢復排程。"
        }
    } `
        -Action {
        if ($Action -eq 'Enter') {
            $vsanMode = switch ($VsanDataMigration) {
                'EnsureAccessibility' { 'EnsureAccessibility' }
                'Full' { 'Full' }
                'NoDataMigration' { 'NoAction' }
            }
            Write-Host "進入維護模式中 (vSAN mode=$vsanMode)..." -ForegroundColor Yellow
            Set-VMHost -VMHost $vmhost -State Maintenance `
                -VsanDataMigrationMode $vsanMode -Evacuate `
                -RunAsync:$false -ErrorAction Stop -Confirm:$false | Out-Null
            $final = (Get-VMHost -Name $VMHostName).ConnectionState
            Write-Host "完成，狀態=$final" -ForegroundColor Green
        } else {
            Write-Host '離開維護模式中...' -ForegroundColor Yellow
            Set-VMHost -VMHost $vmhost -State Connected -Confirm:$false -ErrorAction Stop | Out-Null
            $final = (Get-VMHost -Name $VMHostName).ConnectionState
            Write-Host "完成，狀態=$final" -ForegroundColor Green
        }
    }
}
catch {
    Write-Error "維護模式操作失敗：$($_.Exception.Message)"
    throw
}
finally {
    if ($connectedVc) { Disconnect-VCFAll }
}
