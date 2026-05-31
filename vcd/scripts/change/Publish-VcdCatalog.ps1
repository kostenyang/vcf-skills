<#
.SYNOPSIS
    發佈 / 散布 VCD Catalog：對外發佈 (publish externally) 或分享給指定 Org。
    會改動環境 → 以 Invoke-VCFChange 包裝。
.DESCRIPTION
    兩種散布模式：
      - PublishExternal：將 catalog 設為對外發佈 (供其他站點 subscribe)。
      - ShareToOrg     ：將 catalog 分享給指定 Organization (讀取權限)。

    發佈 (依官方 API 文件，schema 以官方為準)：
      PUT  /cloudapi/1.0.0/catalogs/{catalogUrn}/access (分享控制) — 以官方 OpenAPI 為準
      或 legacy: POST /api/admin/catalog/{id}/action/publishToExternalOrganizations
    確切端點/媒體型別依 API 版本而異，正式套用前請於 UAT 驗證。
      https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/-vcloud-api-programming-guide-for-service-providers-10-6.html
.PARAMETER Environment
    uat | test | prod。
.PARAMETER CatalogName  目標 catalog 名稱。
.PARAMETER Mode         PublishExternal | ShareToOrg。
.PARAMETER TargetOrg    Mode=ShareToOrg 時的目標 Org 名稱。
.EXAMPLE
    ./Publish-VcdCatalog.ps1 -Environment uat -CatalogName base-templates -Mode PublishExternal
.EXAMPLE
    ./Publish-VcdCatalog.ps1 -Environment prod -CatalogName base-templates -Mode ShareToOrg -TargetOrg acme -ForceProdChange -ChangeTicket CHG0012347
.NOTES
    REST 路徑/schema 以官方 VMware Cloud Director Programming Guide / OpenAPI 為準。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$CatalogName,
    [Parameter(Mandatory)][ValidateSet('PublishExternal','ShareToOrg')][string]$Mode,
    [string]$TargetOrg,
    [switch]$ForceProdChange,
    [string]$ChangeTicket,
    [string]$ApiVersion = '38.1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Mode -eq 'ShareToOrg' -and [string]::IsNullOrWhiteSpace($TargetOrg)) {
    throw "Mode=ShareToOrg 需提供 -TargetOrg。"
}

$repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
Import-Module (Join-Path $repoRoot 'lib/VCFGuardrails.psm1') -Force
Import-Module (Join-Path $repoRoot 'lib/VCFConnect.psm1')   -Force
Import-Module (Join-Path $PSScriptRoot '../lib/VCDApi.psm1') -Force

$conn = $null
try {
    $env = Get-VCFEnvironment -Name $Environment
    $conn = Connect-VcdApi -Environment $env -ApiVersion $ApiVersion

    # 解析 catalog
    $cats = Get-VcdPagedResult -Conn $conn -Path "/cloudapi/1.0.0/catalogs?filter=name==$CatalogName"
    $cat = @($cats) | Where-Object { $_.name -eq $CatalogName } | Select-Object -First 1
    if (-not $cat) { throw "找不到 catalog '$CatalogName'。" }
    $catId = $cat.id

    if ($Mode -eq 'PublishExternal') {
        $path = "/cloudapi/1.0.0/catalogs/$catId/action/publishToExternalOrganizations"  # 以官方 API 文件為準
        $body = @{ isPublishedExternally = $true }
        $desc = "對外發佈 catalog '$CatalogName'"
        $preview = {
            "POST $($conn.BaseUri)$path"
            "目標：將 catalog 設為對外發佈，供其他站點 subscribe。"
            ($body | ConvertTo-Json)
        }
        $action = {
            Invoke-VcdApi -Conn $conn -Path $path -Method Post -Body $body | Out-Null
            Write-Host "catalog '$CatalogName' 已對外發佈。" -ForegroundColor Green
        }
    }
    else {
        # 解析目標 Org URN
        $orgs = Get-VcdPagedResult -Conn $conn -Path "/cloudapi/1.0.0/orgs?filter=name==$TargetOrg"
        $org = @($orgs) | Where-Object { $_.name -eq $TargetOrg } | Select-Object -First 1
        if (-not $org) { throw "找不到目標 Org '$TargetOrg'。" }

        $path = "/cloudapi/1.0.0/catalogs/$catId/accessControl"  # 以官方 OpenAPI 為準
        $body = @{
            accessLevelId = 'urn:vcloud:accessLevel:ReadOnly'
            subjects = @( @{ accessLevelId = 'urn:vcloud:accessLevel:ReadOnly'; subject = @{ name = $org.name; id = $org.id } } )
        }
        $desc = "將 catalog '$CatalogName' 分享給 Org '$TargetOrg' (唯讀)"
        $preview = {
            "PUT $($conn.BaseUri)$path"
            "目標 Org：$TargetOrg ($($org.id))，存取層級：ReadOnly"
            ($body | ConvertTo-Json -Depth 6)
        }
        $action = {
            Invoke-VcdApi -Conn $conn -Path $path -Method Put -Body $body | Out-Null
            Write-Host "catalog '$CatalogName' 已分享給 Org '$TargetOrg'。" -ForegroundColor Green
        }
    }

    Invoke-VCFChange -Environment $env `
        -Description $desc `
        -Impact 'Change' `
        -ForceProdChange:$ForceProdChange `
        -ChangeTicket $ChangeTicket `
        -Preview $preview `
        -Action $action
}
catch {
    Write-Error "Catalog 發佈/散布失敗：$($_.Exception.Message)"
    exit 1
}
finally {
    if ($conn) { Disconnect-VcdApi -Conn $conn }
}
