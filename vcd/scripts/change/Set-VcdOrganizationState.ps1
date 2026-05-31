<#
.SYNOPSIS
    啟用 / 停用 VCD Organization (租戶)。會改動環境 → 以 Invoke-VCFChange 包裝。
.DESCRIPTION
    停用租戶屬高影響操作 (租戶將無法登入 / 使用)，故：
      - 預設 Impact=Change；停用 (-Enable:$false) 視為 Destructive，PROD 需額外 DESTROY 確認。
    啟用/停用 (依官方 API 文件)：
      POST /cloudapi/1.0.0/orgs/{orgUrn}/actions/enable
      POST /cloudapi/1.0.0/orgs/{orgUrn}/actions/disable
      (action 端點以官方 OpenAPI 為準；不同版本可能改以 PUT /orgs/{id} 更新 isEnabled。)
.PARAMETER Environment
    uat | test | prod。
.PARAMETER OrgName
    目標 Org 的系統名稱。
.PARAMETER Enable
    $true=啟用；$false=停用 (預設 $true)。
.EXAMPLE
    ./Set-VcdOrganizationState.ps1 -Environment uat -OrgName acme -Enable:$false
.EXAMPLE
    ./Set-VcdOrganizationState.ps1 -Environment prod -OrgName acme -Enable:$false -ForceProdChange -ChangeTicket CHG0012346
.NOTES
    REST 路徑以官方 VMware Cloud Director OpenAPI 為準。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$OrgName,
    [bool]$Enable = $true,
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

    # 先以唯讀查詢解析 Org URN/id
    $orgs = Get-VcdPagedResult -Conn $conn -Path "/cloudapi/1.0.0/orgs?filter=name==$OrgName"
    $org = @($orgs) | Where-Object { $_.name -eq $OrgName } | Select-Object -First 1
    if (-not $org) { throw "找不到 Org '$OrgName'。" }
    $orgId = $org.id   # URN, e.g. urn:vcloud:org:xxxx

    $verb   = if ($Enable) { 'enable' } else { 'disable' }
    $impact = if ($Enable) { 'Change' } else { 'Destructive' }   # 停用視為破壞性
    $path   = "/cloudapi/1.0.0/orgs/$orgId/actions/$verb"

    Invoke-VCFChange -Environment $env `
        -Description "$verb Organization '$OrgName' ($orgId)" `
        -Impact $impact `
        -ForceProdChange:$ForceProdChange `
        -ChangeTicket $ChangeTicket `
        -Preview {
            "POST $($conn.BaseUri)$path"
            "目前 isEnabled = $($org.isEnabled) → 目標 $($Enable)"
            if (-not $Enable) { '警告：停用後該租戶使用者將無法登入 / 使用資源。' }
        } `
        -Action {
            Invoke-VcdApi -Conn $conn -Path $path -Method Post | Out-Null
            Write-Host ("Org '{0}' 已{1}。" -f $OrgName, $(if ($Enable) {'啟用'} else {'停用'})) -ForegroundColor Green
        }
}
catch {
    Write-Error "變更 Organization 狀態失敗：$($_.Exception.Message)"
    exit 1
}
finally {
    if ($conn) { Disconnect-VcdApi -Conn $conn }
}
