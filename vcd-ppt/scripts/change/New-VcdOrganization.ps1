<#
.SYNOPSIS
    建立 VCD Organization (租戶)。會改動環境 → 一律以 Invoke-VCFChange 包裝。
.DESCRIPTION
    依硬性規則：變更類操作包在 Invoke-VCFChange 內，提供 -Preview (dry-run) 與 -Action；
    PROD 由框架自動加嚴 (二次確認 / 單號 / 備份)。

    建立流程 (依官方 API 文件)：
      POST /cloudapi/1.0.0/orgs
      body: { name, displayName, description, isEnabled }
      參考: https://developer.broadcom.com/xapis/vmware-cloud-director-openapi/latest/cloudapi/1.0.0/orgs/post/
.PARAMETER Environment
    uat | test | prod。
.PARAMETER OrgName
    Org 的系統名稱 (URL-safe，建立後不可改)。
.PARAMETER DisplayName
    顯示名稱。
.PARAMETER Description
    描述。
.PARAMETER Enabled
    建立後是否啟用 (預設 $true)。
.PARAMETER ForceProdChange
    PROD 提權旗標 (傳遞給 Invoke-VCFChange)。
.PARAMETER ChangeTicket
    變更單號 (PROD 需要)。
.EXAMPLE
    ./New-VcdOrganization.ps1 -Environment uat -OrgName acme -DisplayName 'ACME Corp'
.EXAMPLE
    ./New-VcdOrganization.ps1 -Environment prod -OrgName acme -DisplayName 'ACME Corp' -ForceProdChange -ChangeTicket CHG0012345
.NOTES
    REST 路徑以官方 VMware Cloud Director OpenAPI 為準。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$OrgName,
    [Parameter(Mandatory)][string]$DisplayName,
    [string]$Description = '',
    [bool]$Enabled = $true,
    [switch]$ForceProdChange,
    [string]$ChangeTicket,
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
    $conn = Connect-VcdApi -Environment $env -ApiVersion $ApiVersion

    $body = @{
        name        = $OrgName
        displayName = $DisplayName
        description = $Description
        isEnabled   = $Enabled
    }

    Invoke-VCFChange -Environment $env `
        -Description "建立 Organization '$OrgName' ($DisplayName)" `
        -Impact 'Change' `
        -ForceProdChange:$ForceProdChange `
        -ChangeTicket $ChangeTicket `
        -Preview {
            "POST $($conn.BaseUri)/cloudapi/1.0.0/orgs"
            "Body:"
            ($body | ConvertTo-Json -Depth 5)
        } `
        -Action {
            $result = Invoke-VcdApi -Conn $conn -Path '/cloudapi/1.0.0/orgs' -Method Post -Body $body
            Write-Host ("已建立 Org: name={0} id={1}" -f $result.name, $result.id) -ForegroundColor Green
        }
}
catch {
    Write-Error "建立 Organization 失敗：$($_.Exception.Message)"
    exit 1
}
finally {
    if ($conn) { Disconnect-VcdApi -Conn $conn }
}
