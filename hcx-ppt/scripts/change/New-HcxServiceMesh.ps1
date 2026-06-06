<#
.SYNOPSIS
    建立 HCX Service Mesh (變更)。以 Invoke-VCFChange 包裝，先 dry-run 預覽後執行。
.DESCRIPTION
    依指定的 site pairing、Compute Profile、Network Profile 與服務集合
    (HCX-IX / HCX-NE) 建立 Service Mesh。
    所有改動均透過 lib 框架護欄：UAT/TEST 單次確認；PROD 需 -ForceProdChange
    + 變更單號 + 備份確認 + 二次確認。

    HCX REST：POST https://<HcxManager>/hybridity/api/interconnect/serviceMesh
    body 結構 (compute/network profile id、service 清單) 以官方 API 文件為準：
      https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11.html
.PARAMETER Environment
    uat | test | prod。
.PARAMETER MeshName
    要建立的 Service Mesh 名稱。
.PARAMETER RemoteSiteName
    已配對的遠端站台名稱 (對應 /cloudConfigs 的 name)。
.PARAMETER SourceComputeProfile
    來源端 Compute Profile 名稱。
.PARAMETER RemoteComputeProfile
    目的端 Compute Profile 名稱。
.PARAMETER Services
    要啟用的服務，預設 INTERCONNECT,NETWORK_EXTENSION。
.PARAMETER ForceProdChange
    PROD 提權旗標。
.PARAMETER ChangeTicket
    PROD 變更單號。
.EXAMPLE
    ./New-HcxServiceMesh.ps1 -Environment uat -MeshName SM-UAT -RemoteSiteName cloud-uat `
        -SourceComputeProfile CP-Src -RemoteComputeProfile CP-Dst
.NOTES
    需先 Import-Module lib/VCFGuardrails.psm1, lib/VCFConnect.psm1。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$MeshName,
    [Parameter(Mandatory)][string]$RemoteSiteName,
    [Parameter(Mandatory)][string]$SourceComputeProfile,
    [Parameter(Mandatory)][string]$RemoteComputeProfile,
    [string[]]$Services = @('INTERCONNECT','NETWORK_EXTENSION'),
    [switch]$ForceProdChange,
    [string]$ChangeTicket
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Import-Module (Join-Path $repo 'lib/VCFGuardrails.psm1') -Force
Import-Module (Join-Path $repo 'lib/VCFConnect.psm1')   -Force

try {
    $env = Get-VCFEnvironment -Name $Environment
    $tok = Get-VCFRestToken -Environment $env -Service HCX
    $base = "$($tok.BaseUri)/hybridity/api"

    # Service Mesh 建立 body (欄位以官方 API 文件為準)
    $body = @{
        name = $MeshName
        sourceSite = @{ name = 'local' }
        destinationSite = @{ name = $RemoteSiteName }
        sourceComputeProfile = @{ name = $SourceComputeProfile }
        destinationComputeProfile = @{ name = $RemoteComputeProfile }
        services = @($Services | ForEach-Object { @{ name = $_ } })
    }

    Invoke-VCFChange -Environment $env -Impact Change `
        -Description "建立 HCX Service Mesh '$MeshName' (site=$RemoteSiteName, services=$($Services -join '+'))" `
        -ForceProdChange:$ForceProdChange -ChangeTicket $ChangeTicket `
        -Preview {
            "將以下列設定建立 Service Mesh (dry-run)："
            ($body | ConvertTo-Json -Depth 8)
            "目標：POST $base/interconnect/serviceMesh"
        } `
        -Action {
            $uri = "$base/interconnect/serviceMesh"
            $r = Invoke-RestMethod -Method POST -Uri $uri -Headers $tok.Header `
                    -Body ($body | ConvertTo-Json -Depth 8) -ContentType 'application/json' -SkipCertificateCheck
            Write-Host "已提交建立，回應 jobId/serviceMeshId：" -ForegroundColor Green
            $r | ConvertTo-Json -Depth 6 | Write-Host
            Write-Host "請以 Get-HcxHealth.ps1 -Environment $Environment 確認 appliance/tunnel 起來。" -ForegroundColor Cyan
        }
}
catch {
    Write-Error "建立 Service Mesh 失敗：$($_.Exception.Message)"
    throw
}
# 本腳本未連 vCenter，故不需 Disconnect-VCFAll。
