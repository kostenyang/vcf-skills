<#
.SYNOPSIS
    VCF 9 唯讀健檢：透過 SDDC Manager REST + PowerCLI 收集 Fleet/Domain/Cluster/Host/vSAN/NSX 狀態與版本。

.DESCRIPTION
    純唯讀 (ReadOnly)，不會改動任何環境。收集項目：
      1. SDDC Manager / VCF Instance 版本 (BOM)
      2. Domain 清單與狀態
      3. Cluster 清單、是否 vLCM image-based
      4. ESX host 連線狀態與版本 (REST + PowerCLI 交叉驗證)
      5. vSAN 健康 (PowerCLI)
      6. NSX Manager 叢集狀態 (REST)
      7. 系統告警摘要 (SDDC Manager)
    所有 SDDC Manager / NSX REST 路徑以官方 API 文件為準：
      https://developer.broadcom.com/xapis (VMware Cloud Foundation API Reference)

.PARAMETER Environment
    目標環境名稱：uat | test | prod。由 Get-VCFEnvironment 解析。

.PARAMETER SkipPowerCLI
    僅做 REST 盤點，不連 vCenter (適合無 PowerCLI 的跳板機)。

.PARAMETER OutputJson
    將彙整結果額外輸出成 JSON 檔的路徑 (選填)。

.EXAMPLE
    ./Get-Vcf9Health.ps1 -Environment prod

.EXAMPLE
    ./Get-Vcf9Health.ps1 -Environment uat -OutputJson ./uat-health.json

.NOTES
    安全分級：ReadOnly。可直接於 PROD 執行。
    依賴：lib/VCFGuardrails.psm1、lib/VCFConnect.psm1、VMware.PowerCLI、SecretManagement。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat', 'test', 'prod')][string]$Environment,
    [switch]$SkipPowerCLI,
    [string]$OutputJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- 載入共用框架 (相對本腳本往上三層至 repo 根的 lib/) ---
$libRoot = Join-Path $PSScriptRoot '..\..\..\lib'
Import-Module (Join-Path $libRoot 'VCFGuardrails.psm1') -Force
Import-Module (Join-Path $libRoot 'VCFConnect.psm1') -Force

$connectedVc = $false
$report = [ordered]@{
    GeneratedAt = (Get-Date).ToString('s')
    Environment = $Environment
    SddcManager = $null
    Domains     = @()
    Clusters    = @()
    Hosts       = @()
    Nsx         = @()
    Alerts      = @()
    Vsan        = @()
}

try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host '[健檢] 模式 = ReadOnly (不會變更環境)' -ForegroundColor Green

    # ================= SDDC Manager REST =================
    $sddc = Get-VCFRestToken -Environment $env -Service SDDC
    $hdr = $sddc.Header
    $base = $sddc.BaseUri

    function Invoke-SddcGet {
        param([Parameter(Mandatory)][string]$Path)
        Invoke-RestMethod -Method Get -Uri "$base$Path" -Headers $hdr -SkipCertificateCheck -ErrorAction Stop
    }

    # 1) SDDC Manager / VCF 版本 (BOM)  ── 路徑以官方 API 文件為準
    Write-Host "`n== SDDC Manager / VCF 版本 ==" -ForegroundColor Cyan
    try {
        $mgr = Invoke-SddcGet -Path '/v1/sddc-managers'
        $report.SddcManager = $mgr.elements | Select-Object id, version, fqdn
        $report.SddcManager | Format-Table -AutoSize | Out-Host
    } catch {
        Write-Warning "取得 SDDC Manager 版本失敗：$($_.Exception.Message)"
    }

    # 2) Domains
    Write-Host "`n== VCF Domains ==" -ForegroundColor Cyan
    $domains = Invoke-SddcGet -Path '/v1/domains'
    $report.Domains = $domains.elements | Select-Object id, name, type, status
    $report.Domains | Format-Table -AutoSize | Out-Host

    # 3) Clusters (含是否 vLCM image-based)
    Write-Host "`n== Clusters ==" -ForegroundColor Cyan
    $clusters = Invoke-SddcGet -Path '/v1/clusters'
    $report.Clusters = $clusters.elements | ForEach-Object {
        [pscustomobject]@{
            Id            = $_.id
            Name          = $_.name
            Status        = $_.status
            # VCF 9 全面 image-based；isImageBased 欄位以官方 API 為準，缺值時標記未知
            IsImageBased  = if ($_.PSObject.Properties.Name -contains 'isImageBased') { $_.isImageBased } else { '未知(查API)' }
            PrimaryDsType = if ($_.PSObject.Properties.Name -contains 'primaryDatastoreType') { $_.primaryDatastoreType } else { '' }
        }
    }
    $report.Clusters | Format-Table -AutoSize | Out-Host

    # 4) Hosts (REST 視角)
    Write-Host "`n== ESX Hosts (SDDC Manager 視角) ==" -ForegroundColor Cyan
    $hosts = Invoke-SddcGet -Path '/v1/hosts'
    $report.Hosts = $hosts.elements | Select-Object id, fqdn, status,
    @{N = 'EsxVersion'; E = { $_.esxiVersion } }, @{N = 'DomainId'; E = { $_.domain.id } }
    $report.Hosts | Format-Table -AutoSize | Out-Host

    # 5) 系統告警  ── 路徑以官方 API 文件為準
    Write-Host "`n== 系統告警 (SDDC Manager) ==" -ForegroundColor Cyan
    try {
        $alerts = Invoke-SddcGet -Path '/v1/system/alerts'
        $report.Alerts = $alerts.elements | Where-Object { $_.severity -in @('CRITICAL', 'WARNING') } |
        Select-Object severity, message, @{N = 'Resource'; E = { $_.resource.name } }
        if ($report.Alerts) { $report.Alerts | Format-Table -AutoSize | Out-Host }
        else { Write-Host '無 CRITICAL/WARNING 告警。' -ForegroundColor Green }
    } catch {
        Write-Warning "取得告警失敗 (端點名稱依版本可能不同，以官方 API 為準)：$($_.Exception.Message)"
    }

    # ================= NSX REST =================
    if ($env.Nsx) {
        Write-Host "`n== NSX Manager 叢集狀態 ==" -ForegroundColor Cyan
        try {
            $nsx = Get-VCFRestToken -Environment $env -Service NSX
            # NSX-T Policy API：/api/v1/cluster/status  (以官方 NSX API 文件為準)
            $cl = Invoke-RestMethod -Method Get -Uri "$($nsx.BaseUri)/api/v1/cluster/status" `
                -Headers $nsx.Header -SkipCertificateCheck -ErrorAction Stop
            $report.Nsx = [pscustomobject]@{
                OverallStatus = $cl.detailed_cluster_status.overall_status
                ControlGroup  = $cl.control_cluster_status.status
                MgmtGroup     = $cl.mgmt_cluster_status.status
            }
            $report.Nsx | Format-List | Out-Host
        } catch {
            Write-Warning "NSX 健檢失敗：$($_.Exception.Message)"
        }
    }

    # ================= PowerCLI (vSAN + Host 交叉驗證) =================
    if (-not $SkipPowerCLI) {
        Write-Host "`n== PowerCLI：vSAN 健康 + Host 連線 ==" -ForegroundColor Cyan
        try {
            Connect-VCFvCenter -Environment $env -AllLinked | Out-Null
            $connectedVc = $true

            $vmHosts = Get-VMHost
            foreach ($h in $vmHosts) {
                Write-Host ("  Host {0,-40} State={1,-12} Ver={2} Build={3}" -f `
                        $h.Name, $h.ConnectionState, $h.Version, $h.Build)
            }

            foreach ($cl in Get-Cluster) {
                $vsanEnabled = $false
                try { $vsanEnabled = (Get-VsanClusterConfiguration -Cluster $cl -ErrorAction Stop).VsanEnabled } catch {}
                if ($vsanEnabled) {
                    try {
                        $hc = Test-VsanClusterHealth -Cluster $cl -ErrorAction Stop
                        $row = [pscustomobject]@{ Cluster = $cl.Name; OverallHealth = $hc.OverallHealth }
                    } catch {
                        $row = [pscustomobject]@{ Cluster = $cl.Name; OverallHealth = "查詢失敗:$($_.Exception.Message)" }
                    }
                    $report.Vsan += $row
                    $row | Format-Table -AutoSize | Out-Host
                }
            }
        } catch {
            Write-Warning "PowerCLI 健檢失敗：$($_.Exception.Message)"
        }
    } else {
        Write-Host "`n[略過] PowerCLI 區段 (-SkipPowerCLI)" -ForegroundColor DarkGray
    }

    # ================= 輸出 =================
    if ($OutputJson) {
        $report | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputJson -Encoding utf8
        Write-Host "`n已輸出 JSON：$OutputJson" -ForegroundColor Green
    }
    Write-Host "`n✓ 健檢完成 (ReadOnly)。" -ForegroundColor Green
}
catch {
    Write-Error "健檢中止：$($_.Exception.Message)"
    throw
}
finally {
    if ($connectedVc) { Disconnect-VCFAll }
}
