<#
.SYNOPSIS
    建立 HCX Network Extension (L2 延伸, 變更)。以 Invoke-VCFChange 包裝。
.DESCRIPTION
    將來源端網段透過指定 Service Mesh 延伸到目的端，VM 搬遷後保留 IP/MAC。
    可選擇啟用 MON (Mobility Optimized Networking) 以避免 tromboning。

    HCX REST：POST https://<HcxManager>/hybridity/api/l2Extensions
    body 欄位 (networkId、serviceMeshId、gateway、MON) 以官方 API 文件為準：
      https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11.html
.PARAMETER Environment
    uat | test | prod。
.PARAMETER NetworkName
    要延伸的來源網段名稱 (DVPG / NSX segment)。
.PARAMETER ServiceMeshName
    承載此延伸的 Service Mesh 名稱。
.PARAMETER DestinationT1
    目的端 T1 Gateway 名稱 (供 MON / gateway 設定)。
.PARAMETER GatewayCidr
    延伸網段在目的端的閘道 CIDR，例如 '10.10.10.1/24'。
.PARAMETER EnableMON
    是否啟用 MON。
.PARAMETER ForceProdChange
    PROD 提權旗標。
.PARAMETER ChangeTicket
    PROD 變更單號。
.EXAMPLE
    ./New-HcxNetworkExtension.ps1 -Environment uat -NetworkName 'app-seg' `
        -ServiceMeshName SM-UAT -DestinationT1 T1-App -GatewayCidr '10.10.10.1/24' -EnableMON
.NOTES
    需先 Import-Module lib/VCFGuardrails.psm1, lib/VCFConnect.psm1。
    MON 為 HCX Enterprise 能力 (VCF 5.1.1+/HCX 4.9+ 自動繼承)。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$NetworkName,
    [Parameter(Mandatory)][string]$ServiceMeshName,
    [Parameter(Mandatory)][string]$DestinationT1,
    [Parameter(Mandatory)][string]$GatewayCidr,
    [switch]$EnableMON,
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

    # Network Extension body (欄位以官方 API 文件為準)
    $body = @{
        extensions = @(
            @{
                serviceMeshName = $ServiceMeshName
                network = @{ name = $NetworkName }
                destinationNetwork = @{
                    gatewayName = $DestinationT1
                    gatewayCidr = $GatewayCidr
                }
                features = @{
                    # MON：在 SDDC 端 T1 以 /32 啟用閘道並加靜態路由 (不向 on-prem 通告)
                    mobilityOptimizedNetworking = [bool]$EnableMON
                }
            }
        )
    }

    Invoke-VCFChange -Environment $env -Impact Change `
        -Description "建立 Network Extension '$NetworkName' (mesh=$ServiceMeshName, MON=$([bool]$EnableMON))" `
        -ForceProdChange:$ForceProdChange -ChangeTicket $ChangeTicket `
        -Preview {
            "將延伸網段 (dry-run)："
            ($body | ConvertTo-Json -Depth 8)
            "目標：POST $base/l2Extensions"
            if ($EnableMON) { "MON 啟用：請確認 MON Route Policy 已規劃 (出向符合策略→回來源；否則走 T0)。" }
        } `
        -Action {
            $uri = "$base/l2Extensions"
            $r = Invoke-RestMethod -Method POST -Uri $uri -Headers $tok.Header `
                    -Body ($body | ConvertTo-Json -Depth 8) -ContentType 'application/json' -SkipCertificateCheck
            Write-Host "已提交網段延伸，回應：" -ForegroundColor Green
            $r | ConvertTo-Json -Depth 6 | Write-Host
            Write-Host "請以 Get-HcxHealth.ps1 確認 NE 狀態為 UP。" -ForegroundColor Cyan
        }
}
catch {
    Write-Error "建立 Network Extension 失敗：$($_.Exception.Message)"
    throw
}
