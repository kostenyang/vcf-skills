<#
.SYNOPSIS
    將 ESXi host 進入 / 離開維護模式 (變更操作，走護欄)。
.DESCRIPTION
    升級或硬體維護時常需將 host 進入維護模式。本腳本以 PowerCLI 執行，
    進入維護模式時可指定 vSAN 資料疏散模式 (EnsureAccessibility / FullDataMigration
    / NoAction)。屬『變更』操作，一律包在 Invoke-VCFChange 內並先 dry-run；
    PROD 由框架自動加嚴。
.PARAMETER Environment
    目標環境名稱：uat | test | prod。
.PARAMETER VMHostName
    目標 ESXi host FQDN。
.PARAMETER Action
    Enter (進入維護) 或 Exit (離開維護)。
.PARAMETER VsanDataMigration
    進入維護時的 vSAN 資料疏散模式 (預設 EnsureAccessibility)。
.PARAMETER ForceProdChange
    PROD 提權旗標 (PROD 必填)。
.PARAMETER ChangeTicket
    變更單號。
.EXAMPLE
    ./Set-Vcf521HostMaintenance.ps1 -Environment test -VMHostName esx01.test.local -Action Enter
.EXAMPLE
    ./Set-Vcf521HostMaintenance.ps1 -Environment prod -VMHostName esx01.prod.local -Action Exit -ForceProdChange -ChangeTicket CHG0012345
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$VMHostName,
    [Parameter(Mandatory)][ValidateSet('Enter','Exit')][string]$Action,
    [ValidateSet('EnsureAccessibility','FullDataMigration','NoAction')]
    [string]$VsanDataMigration = 'EnsureAccessibility',
    [switch]$ForceProdChange,
    [string]$ChangeTicket
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot/../../../lib/VCFGuardrails.psm1" -Force
Import-Module "$PSScriptRoot/../../../lib/VCFConnect.psm1"   -Force

$connected = $false
try {
    $env = Get-VCFEnvironment -Name $Environment
    Connect-VCFvCenter -Environment $env | Out-Null
    $connected = $true

    $vmhost = Get-VMHost -Name $VMHostName -ErrorAction Stop
    $impact = if ($Action -eq 'Enter') { 'Change' } else { 'Change' }

    Invoke-VCFChange -Environment $env `
        -Description "$Action 維護模式：$VMHostName (vSAN 疏散=$VsanDataMigration)" `
        -Impact $impact `
        -ForceProdChange:$ForceProdChange `
        -ChangeTicket $ChangeTicket `
        -Preview {
            if ($Action -eq 'Enter') {
                "將使 host '$VMHostName' (目前狀態=$($vmhost.ConnectionState)) 進入維護模式，" +
                "vSAN 資料疏散模式=$VsanDataMigration。請確認該 host 上 VM 已可遷移/已淨空。"
            } else {
                "將使 host '$VMHostName' (目前狀態=$($vmhost.ConnectionState)) 離開維護模式。"
            }
        } `
        -Action {
            if ($Action -eq 'Enter') {
                $vmhost | Set-VMHost -State Maintenance -VsanDataMigrationMode $VsanDataMigration -Confirm:$false | Out-Null
                Write-Host "host '$VMHostName' 已進入維護模式。" -ForegroundColor Green
            } else {
                $vmhost | Set-VMHost -State Connected -Confirm:$false | Out-Null
                Write-Host "host '$VMHostName' 已離開維護模式。" -ForegroundColor Green
            }
        }
}
catch {
    Write-Error "維護模式操作失敗：$($_.Exception.Message)"
    throw
}
finally {
    if ($connected) { Disconnect-VCFAll }
}
