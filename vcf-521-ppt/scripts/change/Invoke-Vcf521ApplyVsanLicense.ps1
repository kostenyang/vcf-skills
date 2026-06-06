<#
.SYNOPSIS
    套用 vSAN TiB 容量授權 (License Now) 到 cluster (變更操作，走護欄)。
.DESCRIPTION
    VCF 5.2.1 支援 vSAN 以 TiB 容量計價的 License Now 授權。本腳本以 PowerCLI
    將指定的 vSAN 授權金鑰指派到目標叢集。授權變更屬『變更』操作，一律包在
    Invoke-VCFChange 內並先 dry-run 預覽；PROD 由框架自動加嚴。
    註：授權金鑰由 SecretManagement 取得 (LicenseSecretName)，不寫死於腳本。
.PARAMETER Environment
    目標環境名稱：uat | test | prod。
.PARAMETER ClusterName
    目標 vSAN 叢集名稱。
.PARAMETER LicenseSecretName
    SecretManagement 內存放 vSAN 授權金鑰的祕密名稱。
.PARAMETER ForceProdChange
    PROD 提權旗標 (PROD 必填)。
.PARAMETER ChangeTicket
    變更單號。
.EXAMPLE
    ./Invoke-Vcf521ApplyVsanLicense.ps1 -Environment test -ClusterName WLD01-Cluster1 -LicenseSecretName vsan-tib-key
.NOTES
    指派授權的 cmdlet 為 PowerCLI 的 Set-VMHost ... 或 LicenseManager；
    本腳本使用 vSphere LicenseManager 指派，確切流程請對照所在 PowerCLI 版本。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$ClusterName,
    [Parameter(Mandatory)][string]$LicenseSecretName,
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

    $cluster = Get-Cluster -Name $ClusterName -ErrorAction Stop
    # 授權金鑰由 SecretManagement 取得 (不落地明文)
    $licSecret = Get-Secret -Name $LicenseSecretName -AsPlainText -ErrorAction Stop

    Invoke-VCFChange -Environment $env `
        -Description "套用 vSAN 容量授權至叢集 '$ClusterName'" `
        -Impact 'Change' `
        -ForceProdChange:$ForceProdChange `
        -ChangeTicket $ChangeTicket `
        -Preview {
            "將以 LicenseManager 指派 vSAN 授權 (來源祕密=$LicenseSecretName) " +
            "至叢集 '$ClusterName' (含 $($cluster.ExtensionData.Host.Count) 台 host)。`n" +
            '授權內容不顯示於預覽以避免外洩。'
        } `
        -Action {
            $si = Get-View ServiceInstance
            $licMgr = Get-View $si.Content.LicenseManager
            $assignMgr = Get-View $licMgr.LicenseAssignmentManager
            foreach ($vmhost in (Get-VMHost -Location $cluster)) {
                $hostId = ($vmhost | Get-View).MoRef.Value
                $assignMgr.UpdateAssignedLicense($hostId, $licSecret, $null) | Out-Null
                Write-Host "  已指派授權：$($vmhost.Name)" -ForegroundColor Green
            }
            Write-Host '完成 vSAN 容量授權指派。請於 vSphere Client 確認授權狀態與容量。' -ForegroundColor Green
        }
}
catch {
    Write-Error "套用 vSAN 授權失敗：$($_.Exception.Message)"
    throw
}
finally {
    if ($connected) { Disconnect-VCFAll }
}
