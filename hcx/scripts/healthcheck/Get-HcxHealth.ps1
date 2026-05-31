<#
.SYNOPSIS
    HCX 健檢 (唯讀)：site pairing、Service Mesh / IX-NE appliance 健康、tunnel、
    Network Extension 清單與進行中遷移狀態。
.DESCRIPTION
    純查詢，不改動任何環境。透過 lib/ 框架取得 HCX REST token，
    呼叫 HCX Manager 的 /hybridity/api 端點。

    HCX REST 基底：https://<HcxManager>/hybridity/api
    端點路徑以官方 API 文件為準：
      https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11.html
.PARAMETER Environment
    uat | test | prod，由 Get-VCFEnvironment 解析。
.EXAMPLE
    ./Get-HcxHealth.ps1 -Environment uat
.NOTES
    需先 Import-Module lib/VCFGuardrails.psm1, lib/VCFConnect.psm1。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---- 匯入框架 (相對於 repo 根) ----
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Import-Module (Join-Path $repo 'lib/VCFGuardrails.psm1') -Force
Import-Module (Join-Path $repo 'lib/VCFConnect.psm1')   -Force

function Invoke-Hcx {
    param([string]$Method, [string]$Path, $Body, [hashtable]$Token)
    $uri = "$($Token.BaseUri)/hybridity/api$Path"
    $p = @{ Method = $Method; Uri = $uri; Headers = $Token.Header; ContentType = 'application/json'; SkipCertificateCheck = $true }
    if ($Body) { $p.Body = ($Body | ConvertTo-Json -Depth 12) }
    Invoke-RestMethod @p
}

try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host "HCX 健檢 (唯讀) @ $($env.HcxManager)" -ForegroundColor Cyan

    $tok = Get-VCFRestToken -Environment $env -Service HCX

    # 1) Site Pairing 狀態 (本地與遠端雲端設定)
    Write-Host "`n=== Site Pairing ===" -ForegroundColor Green
    # GET /cloudConfigs 回傳已配對的遠端站台
    $pairs = Invoke-Hcx -Method GET -Path '/cloudConfigs' -Token $tok
    $pairList = @($pairs.data.items)
    if (-not $pairList) { Write-Host "  (無 site pairing)" -ForegroundColor Yellow }
    foreach ($p in $pairList) {
        Write-Host ("  {0,-30} url={1}" -f $p.name, $p.url)
    }

    # 2) Service Mesh + appliance (IX/NE) 健康與 tunnel 狀態
    Write-Host "`n=== Service Mesh / Appliance / Tunnel ===" -ForegroundColor Green
    # POST /interconnect/serviceMesh (filter 查詢) -- 路徑以官方 API 文件為準
    $sm = Invoke-Hcx -Method POST -Path '/interconnect/serviceMesh' -Body @{ } -Token $tok
    $meshes = @($sm.items)
    if (-not $meshes) { Write-Host "  (無 Service Mesh)" -ForegroundColor Yellow }
    foreach ($m in $meshes) {
        Write-Host ("  ServiceMesh: {0}" -f $m.name) -ForegroundColor White
        # 查該 mesh 的 appliance 狀態
        # GET /interconnect/serviceMesh/{id}/connections -- 以官方 API 文件為準
        try {
            $appl = Invoke-Hcx -Method GET -Path "/interconnect/serviceMesh/$($m.serviceMeshId)/appliances" -Token $tok
            foreach ($a in @($appl.items)) {
                $tunnel = if ($a.PSObject.Properties.Name -contains 'tunnelStatus') { $a.tunnelStatus } else { 'n/a' }
                $color  = if ($a.status -eq 'UP' -or $tunnel -eq 'UP') { 'Green' } else { 'Red' }
                Write-Host ("    - {0,-22} type={1,-4} status={2} tunnel={3}" -f $a.applianceName, $a.applianceType, $a.status, $tunnel) -ForegroundColor $color
            }
        } catch {
            Write-Host "    (無法取得 appliance 細節：$($_.Exception.Message))" -ForegroundColor Yellow
        }
    }

    # 3) Network Extension 清單
    Write-Host "`n=== Network Extension (L2) ===" -ForegroundColor Green
    # POST /l2Extensions -- 以官方 API 文件為準
    $l2 = Invoke-Hcx -Method GET -Path '/l2Extensions' -Token $tok
    $exts = @($l2.items)
    if (-not $exts) { Write-Host "  (無 Network Extension)" -ForegroundColor Yellow }
    foreach ($e in $exts) {
        $status = if ($e.PSObject.Properties.Name -contains 'status') { $e.status.state } else { 'n/a' }
        Write-Host ("  {0,-30} status={1}" -f $e.networkName, $status)
    }

    # 4) 進行中遷移狀態
    Write-Host "`n=== 進行中 / 近期遷移 ===" -ForegroundColor Green
    # POST /migrations?action=query -- 以官方 API 文件為準
    $migBody = @{ filter = @{ migrationType = @() } ; options = @{ } }
    $mig = Invoke-Hcx -Method POST -Path '/migrations?action=query' -Body $migBody -Token $tok
    $items = @($mig.items)
    $active = $items | Where-Object { $_.migrationInfo.progressDetails.diskTransferPercentage -lt 100 -or $_.state -in @('MIGRATING','RUNNING','TRANSFER') }
    if (-not $active) { Write-Host "  (目前無進行中遷移)" -ForegroundColor Yellow }
    foreach ($mi in @($active)) {
        Write-Host ("  VM={0,-25} type={1,-6} state={2}" -f $mi.migrationInfo.entityName, $mi.migrationType, $mi.state)
    }

    Write-Host "`n健檢完成 (唯讀，未改動環境)。" -ForegroundColor Cyan
}
catch {
    Write-Error "HCX 健檢失敗：$($_.Exception.Message)"
    throw
}
# 本腳本未連 vCenter，故不需 Disconnect-VCFAll。
