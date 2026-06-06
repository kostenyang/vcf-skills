<#
.SYNOPSIS
    建立 VMware Cloud Director Organization VDC (OrgVDC)，含 CPU/記憶體/儲存配額。
    會改動環境 → 以 Invoke-VCFChange 包裝。
.DESCRIPTION
    OrgVDC 是租戶實際消費的資源切片，需指定：
      - 所屬 Organization、來源 Provider VDC (PVDC)
      - 配置模型 AllocationModel：AllocationVApp(PAYG) / AllocationPool / ReservationPool / Flex
      - CPU / 記憶體 配額與儲存原則 (storageProfile) 限額

    OrgVDC 建立屬 System Admin 範疇，多以「legacy admin API」執行：
      POST /api/admin/org/{org-id}/vdcsparams
      (Accept/Content-Type: application/*+xml 或 +json，依協商版本)
    或 cloudapi 對應端點；確切 schema「以官方 API 文件為準」：
      https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/-vcloud-api-programming-guide-for-service-providers-10-6.html

    本腳本以參數組出 body 並於 Action 內 POST；schema 欄位請依貴環境 API 版本核對。
.PARAMETER Environment
    uat | test | prod。
.PARAMETER OrgName        所屬 Org 系統名稱。
.PARAMETER VdcName        OrgVDC 名稱。
.PARAMETER ProviderVdc    來源 PVDC 名稱。
.PARAMETER AllocationModel  AllocationVApp | AllocationPool | ReservationPool | Flex。
.PARAMETER CpuLimitMhz    CPU 限額 (MHz)。
.PARAMETER MemoryLimitMb  記憶體限額 (MB)。
.PARAMETER StorageProfile 儲存原則名稱。
.PARAMETER StorageLimitMb 儲存限額 (MB)。
.EXAMPLE
    ./New-VcdOrgVdc.ps1 -Environment uat -OrgName acme -VdcName acme-vdc01 `
        -ProviderVdc PVDC-Gold -AllocationModel AllocationPool `
        -CpuLimitMhz 20000 -MemoryLimitMb 65536 -StorageProfile 'Gold' -StorageLimitMb 512000
.NOTES
    REST 路徑/schema 以官方 VMware Cloud Director Programming Guide 為準。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$OrgName,
    [Parameter(Mandatory)][string]$VdcName,
    [Parameter(Mandatory)][string]$ProviderVdc,
    [ValidateSet('AllocationVApp','AllocationPool','ReservationPool','Flex')]
    [string]$AllocationModel = 'AllocationPool',
    [Parameter(Mandatory)][int]$CpuLimitMhz,
    [Parameter(Mandatory)][int]$MemoryLimitMb,
    [Parameter(Mandatory)][string]$StorageProfile,
    [Parameter(Mandatory)][int]$StorageLimitMb,
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

    # 解析 Org (取得建立 vdc 所需的 admin org 連結/id)
    $orgs = Get-VcdPagedResult -Conn $conn -Path "/cloudapi/1.0.0/orgs?filter=name==$OrgName"
    $org = @($orgs) | Where-Object { $_.name -eq $OrgName } | Select-Object -First 1
    if (-not $org) { throw "找不到 Org '$OrgName'。" }

    # 建立 vdcsparams body (欄位以官方 API schema 為準；此為常見結構範例)
    $body = [ordered]@{
        name            = $VdcName
        allocationModel = $AllocationModel
        computeCapacity = @{
            cpu    = @{ units = 'MHz'; limit = $CpuLimitMhz }
            memory = @{ units = 'MB';  limit = $MemoryLimitMb }
        }
        vdcStorageProfile = @(
            @{ name = $StorageProfile; enabled = $true; limit = $StorageLimitMb; units = 'MB'; default = $true }
        )
        providerVdcName = $ProviderVdc
        isEnabled       = $true
    }

    # 建立端點：System admin org vdc params (以官方 API 文件為準)
    $path = "/api/admin/org/$($org.id -replace '^urn:vcloud:org:','')/vdcsparams"

    Invoke-VCFChange -Environment $env `
        -Description "在 Org '$OrgName' 建立 OrgVDC '$VdcName' (模型=$AllocationModel)" `
        -Impact 'Change' `
        -ForceProdChange:$ForceProdChange `
        -ChangeTicket $ChangeTicket `
        -Preview {
            "POST $($conn.BaseUri)$path"
            "配額：CPU=$CpuLimitMhz MHz, MEM=$MemoryLimitMb MB, 儲存($StorageProfile)=$StorageLimitMb MB"
            "PVDC：$ProviderVdc"
            "Body (schema 以官方 API 文件為準):"
            ($body | ConvertTo-Json -Depth 6)
            ''
            '注意：vdcsparams 之確切 schema 與媒體型別依 API 版本而異，正式套用前請於 UAT 驗證。'
        } `
        -Action {
            $result = Invoke-VcdApi -Conn $conn -Path $path -Method Post -Body $body
            Write-Host ("已送出 OrgVDC 建立請求：{0}" -f $VdcName) -ForegroundColor Green
            if ($result) { $result | Out-Host }
            Write-Host '請以 Get-VcdHealth.ps1 確認 OrgVDC 狀態與配額。' -ForegroundColor Yellow
        }
}
catch {
    Write-Error "建立 OrgVDC 失敗：$($_.Exception.Message)"
    exit 1
}
finally {
    if ($conn) { Disconnect-VcdApi -Conn $conn }
}
