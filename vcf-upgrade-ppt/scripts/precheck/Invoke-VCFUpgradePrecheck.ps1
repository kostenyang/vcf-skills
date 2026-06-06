<#
.SYNOPSIS
    VCF 5.2.x -> 9.0 / 9.1 升級前置全面盤點 (唯讀)。
.DESCRIPTION
    這是升級前最重要的一支腳本，純唯讀，不改動任何環境。
    盤點並針對「目標版本最低需求」逐項輸出 PASS / FAIL / WARN：
      1. 各核心元件版本 (SDDC Manager / NSX / vCenter / ESXi) vs 目標最低需求
      2. 所有 cluster 是否已 vLCM image 化 (baselines 在 VCF 9 不支援)
      3. ELM (Enhanced Linked Mode) 是否啟用 (VCF 9 須停用)
      4. DVS (vSphere Distributed Switch) 版本是否符合目標需求
      5. 備份狀態 (SDDC Manager / NSX / vCenter)
      6. VCF Operations / Fleet 強制元件提醒
    結果可匯出 HTML / CSV / JSON。

    本腳本僅輔助盤點，最終可行性與最低版本需求一律以官方
    VCF Upgrade Planning Tool 與目標版本 Release Notes 為準：
      https://vmware.github.io/vcf-upgrade-planner/
.PARAMETER Environment
    uat | test | prod，由 Get-VCFEnvironment 解析。
.PARAMETER TargetVersion
    目標 VCF 版本字串 (例 9.0.2 / 9.1.0)。僅用於報表標示與最低需求查表。
.PARAMETER OutputDir
    報表輸出目錄，預設為目前目錄下 ./precheck-reports。
.EXAMPLE
    .\Invoke-VCFUpgradePrecheck.ps1 -Environment prod -TargetVersion 9.1.0 -OutputDir C:\reports
.NOTES
    需要：VMware.PowerCLI、Microsoft.PowerShell.SecretManagement。
    REST 路徑以官方 SDDC Manager Public API 文件為準。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$TargetVersion,
    [string]$OutputDir = (Join-Path (Get-Location) 'precheck-reports')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '..\..\..\lib\VCFGuardrails.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '..\..\..\lib\VCFConnect.psm1')    -Force

# ---- 目標版本最低需求查表 (僅作初篩；確切值以官方 Release Notes 為準) ----
# 註：以下為「來源元件至少需到的版本」概念示意，請於執行前對照目標版本官方文件校正。
$MinReq = @{
    '9.0.0' = @{ SddcManager = '5.2.0'; Nsx = '4.2.0'; vCenter = '8.0.3'; Esxi = '8.0.3' }
    '9.0.2' = @{ SddcManager = '5.2.0'; Nsx = '4.2.0'; vCenter = '8.0.3'; Esxi = '8.0.3' }
    '9.1.0' = @{ SddcManager = '9.0.0'; Nsx = '9.0.0'; vCenter = '9.0.0'; Esxi = '9.0.0' }
}

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result {
    param([string]$Category,[string]$Item,[string]$Status,[string]$Detail)
    $results.Add([pscustomobject]@{
        Category = $Category; Item = $Item; Status = $Status; Detail = $Detail
    })
}

function Compare-Version2 {
    # 回傳 $true 表示 actual >= required
    param([string]$Actual,[string]$Required)
    try {
        $a = [version]([regex]::Match($Actual,   '\d+(\.\d+){1,3}').Value)
        $r = [version]([regex]::Match($Required, '\d+(\.\d+){1,3}').Value)
        return ($a -ge $r)
    } catch { return $false }
}

try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host "[Precheck] 目標版本: $TargetVersion (唯讀盤點，不改動環境)" -ForegroundColor Cyan

    if (-not $MinReq.ContainsKey($TargetVersion)) {
        Add-Result 'Meta' "目標版本 $TargetVersion 最低需求表" 'WARN' '本機查表無此版本，請以官方 Release Notes 校正最低需求。'
        $req = $null
    } else {
        $req = $MinReq[$TargetVersion]
    }

    # ============ 1) SDDC Manager 版本 + Domains/Clusters/Hosts (REST) ============
    Write-Host "`n[1] 查詢 SDDC Manager / Domains / Clusters / Hosts ..." -ForegroundColor White
    $sddc = Get-VCFRestToken -Environment $env -Service SDDC
    # GET /v1/sddc-managers (官方 Public API；以官方 API 文件為準)
    try {
        $mgrs = Invoke-RestMethod -Method Get -Uri "$($sddc.BaseUri)/v1/sddc-managers" -Headers $sddc.Header -SkipCertificateCheck
        foreach ($m in @($mgrs.elements)) {
            $ok = if ($req) { Compare-Version2 $m.version $req.SddcManager } else { $true }
            Add-Result 'Component' "SDDC Manager $($m.fqdn)" ($(if($ok){'PASS'}else{'FAIL'})) "目前 $($m.version) / 需 $((if($req){$req.SddcManager}else{'?'}))"
        }
    } catch {
        Add-Result 'Component' 'SDDC Manager 版本' 'WARN' "無法查詢 /v1/sddc-managers：$($_.Exception.Message)"
    }

    # GET /v1/domains
    $domains = @()
    try {
        $domains = @((Invoke-RestMethod -Method Get -Uri "$($sddc.BaseUri)/v1/domains" -Headers $sddc.Header -SkipCertificateCheck).elements)
        Add-Result 'Inventory' 'Workload Domains' 'PASS' "共 $($domains.Count) 個網域：$([string]::Join(', ', ($domains | ForEach-Object { $_.name })))"
    } catch {
        Add-Result 'Inventory' 'Workload Domains' 'WARN' "無法查詢 /v1/domains：$($_.Exception.Message)"
    }

    # GET /v1/upgradables — 官方升級候選 (唯讀)
    try {
        $upg = @((Invoke-RestMethod -Method Get -Uri "$($sddc.BaseUri)/v1/upgradables" -Headers $sddc.Header -SkipCertificateCheck).elements)
        if ($upg.Count -gt 0) {
            Add-Result 'Upgrade' '可升級項目 (upgradables)' 'PASS' "SDDC Manager 回報 $($upg.Count) 筆可升級候選。"
        } else {
            Add-Result 'Upgrade' '可升級項目 (upgradables)' 'WARN' '目前無可升級候選；可能 bundle 尚未下載或版本不符。'
        }
    } catch {
        Add-Result 'Upgrade' '可升級項目 (upgradables)' 'WARN' "無法查詢 /v1/upgradables：$($_.Exception.Message)"
    }

    # ============ 2~4) 連 vCenter 盤點 cluster / vLCM image / ELM / DVS / ESXi ============
    Write-Host "`n[2] 連線 vCenter 盤點 cluster / vLCM / ELM / DVS / ESXi ..." -ForegroundColor White
    Connect-VCFvCenter -Environment $env | Out-Null

    # --- vLCM image vs baseline ---
    foreach ($cluster in (Get-Cluster)) {
        $isImage = $false
        try {
            # vLCM 是否以 image (desired image) 管理；以 PowerCLI 物件屬性偵測
            $cv = Get-View -Id $cluster.Id
            # ClusterComputeResource.configurationEx 內若含 desiredSoftwareSpec 表示已 image 化
            $isImage = $null -ne ($cv.ConfigurationEx.PSObject.Properties['desiredSoftwareSpec'] | Where-Object { $_.Value })
        } catch { $isImage = $false }
        if ($isImage) {
            Add-Result 'vLCM' "Cluster $($cluster.Name)" 'PASS' '已採用 vLCM image。'
        } else {
            Add-Result 'vLCM' "Cluster $($cluster.Name)" 'FAIL' '仍為 baseline / 未 image 化；VCF 9 不支援 baselines，升級前須轉為 vLCM image。'
        }
    }

    # --- ESXi 版本 ---
    foreach ($vmhost in (Get-VMHost)) {
        $ok = if ($req) { Compare-Version2 $vmhost.Version $req.Esxi } else { $true }
        Add-Result 'Component' "ESXi $($vmhost.Name)" ($(if($ok){'PASS'}else{'FAIL'})) "目前 $($vmhost.Version) build $($vmhost.Build) / 需 $((if($req){$req.Esxi}else{'?'}))"
    }

    # --- DVS 版本 ---
    foreach ($vds in (Get-VDSwitch -ErrorAction SilentlyContinue)) {
        Add-Result 'Network' "DVS $($vds.Name)" 'WARN' "DVS 版本 $($vds.Version)；請對照目標 VCF 版本支援的 DVS 版本 (以官方文件為準)，必要時先升級 DVS。"
    }

    # --- ELM (Enhanced Linked Mode) 偵測：同一 SSO domain 是否有多個已連線 vCenter ---
    try {
        $linked = @($global:DefaultVIServers)
        if ($linked.Count -gt 1) {
            Add-Result 'ELM' 'Enhanced Linked Mode' 'FAIL' "偵測到 $($linked.Count) 個連線中的 vCenter，可能啟用 ELM；VCF 9 不支援 ELM，匯入/收斂/升級前須停用。"
        } else {
            Add-Result 'ELM' 'Enhanced Linked Mode' 'WARN' '單一連線無法完全確認 ELM 狀態；請於 vCenter > Linked vCenter Server Systems 再次確認。'
        }
    } catch {
        Add-Result 'ELM' 'Enhanced Linked Mode' 'WARN' "無法判定 ELM 狀態：$($_.Exception.Message)"
    }

    # ============ 5) NSX 版本 (REST) ============
    Write-Host "`n[3] 查詢 NSX 版本 ..." -ForegroundColor White
    try {
        $nsx = Get-VCFRestToken -Environment $env -Service NSX
        # GET /api/v1/node/version (NSX-T/NSX 公用 API；以官方 API 文件為準)
        $nv = Invoke-RestMethod -Method Get -Uri "$($nsx.BaseUri)/api/v1/node/version" -Headers $nsx.Header -SkipCertificateCheck
        $nver = if ($nv.PSObject.Properties['node_version']) { $nv.node_version } elseif ($nv.PSObject.Properties['product_version']) { $nv.product_version } else { "$nv" }
        $ok = if ($req) { Compare-Version2 $nver $req.Nsx } else { $true }
        Add-Result 'Component' 'NSX Manager' ($(if($ok){'PASS'}else{'FAIL'})) "目前 $nver / 需 $((if($req){$req.Nsx}else{'?'}))"
    } catch {
        Add-Result 'Component' 'NSX Manager' 'WARN' "無法查詢 NSX 版本：$($_.Exception.Message)"
    }

    # ============ 6) 備份狀態 (SDDC Manager backup config，唯讀) ============
    Write-Host "`n[4] 查詢備份設定 ..." -ForegroundColor White
    try {
        # GET /v1/system/backup-configuration (以官方 API 文件為準)
        $bk = Invoke-RestMethod -Method Get -Uri "$($sddc.BaseUri)/v1/system/backup-configuration" -Headers $sddc.Header -SkipCertificateCheck
        if ($bk -and ($bk.PSObject.Properties['backupLocations'])) {
            Add-Result 'Backup' 'SDDC Manager 備份設定' 'PASS' '已設定備份目的地；升級前請確認最近一次備份成功且可還原。'
        } else {
            Add-Result 'Backup' 'SDDC Manager 備份設定' 'WARN' '未偵測到備份設定；升級前務必設定並驗證備份。'
        }
    } catch {
        Add-Result 'Backup' 'SDDC Manager 備份設定' 'WARN' "無法查詢備份設定：$($_.Exception.Message)"
    }

    # ============ 6b) VCF Operations / Fleet 強制元件提醒 ============
    Add-Result 'VCF Operations' '強制元件' 'WARN' 'VCF 9.0 起 VCF Operations 為強制元件 (Aria Lifecycle 更名 VCF Fleet Management)；即使原未使用，升級仍會部署。請確認資源與 IP/DNS 規劃 (以 Upgrade Planning Tool 為準)。'

    # ============ 產出報表 ============
    if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $base  = Join-Path $OutputDir "vcf-precheck-$Environment-$stamp"

    $results | Export-Csv -Path "$base.csv" -NoTypeInformation -Encoding UTF8
    $results | ConvertTo-Json -Depth 5 | Out-File "$base.json" -Encoding UTF8

    $fail = @($results | Where-Object Status -eq 'FAIL').Count
    $warn = @($results | Where-Object Status -eq 'WARN').Count
    $pass = @($results | Where-Object Status -eq 'PASS').Count
    $overall = if ($fail -gt 0) { 'FAIL' } elseif ($warn -gt 0) { 'WARN' } else { 'PASS' }

    $rowsHtml = ($results | ForEach-Object {
        $c = switch ($_.Status) { 'PASS' {'#1a7f37'} 'FAIL' {'#cf222e'} default {'#9a6700'} }
        "<tr><td>$($_.Category)</td><td>$($_.Item)</td><td style='color:$c;font-weight:bold'>$($_.Status)</td><td>$($_.Detail)</td></tr>"
    }) -join "`n"
    $html = @"
<!DOCTYPE html><html lang='zh-Hant'><head><meta charset='utf-8'>
<title>VCF 升級 Precheck 報表 - $Environment</title>
<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px}table{border-collapse:collapse;width:100%}th,td{border:1px solid #d0d7de;padding:6px 10px;font-size:13px;text-align:left}th{background:#f6f8fa}h1{font-size:20px}.sum{font-size:14px;margin:8px 0}</style></head>
<body><h1>VCF 升級 Precheck 報表</h1>
<div class='sum'>環境：<b>$Environment</b> ($($env.Tier)) ｜ 目標版本：<b>$TargetVersion</b> ｜ 時間：$stamp</div>
<div class='sum'>總結：<b>$overall</b>　PASS=$pass　WARN=$warn　FAIL=$fail</div>
<table><thead><tr><th>類別</th><th>項目</th><th>狀態</th><th>說明</th></tr></thead><tbody>
$rowsHtml
</tbody></table>
<p style='color:#57606a;font-size:12px'>本報表僅輔助盤點，最終以官方 VCF Upgrade Planning Tool 與目標版本 Release Notes 為準。</p>
</body></html>
"@
    $html | Out-File "$base.html" -Encoding UTF8

    Write-Host "`n========== Precheck 總結 ==========" -ForegroundColor Cyan
    $results | Format-Table Category, Item, Status, Detail -AutoSize | Out-Host
    Write-Host ("總結: {0}  (PASS={1} WARN={2} FAIL={3})" -f $overall,$pass,$warn,$fail) -ForegroundColor $(if($overall -eq 'FAIL'){'Red'}elseif($overall -eq 'WARN'){'Yellow'}else{'Green'})
    Write-Host "報表已輸出：" -ForegroundColor Green
    Write-Host "  $base.html" ; Write-Host "  $base.csv" ; Write-Host "  $base.json"
}
catch {
    Write-Error "Precheck 失敗：$($_.Exception.Message)"
    throw
}
finally {
    Disconnect-VCFAll
}
