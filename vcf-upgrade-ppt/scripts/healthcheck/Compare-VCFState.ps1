<#
.SYNOPSIS
    VCF 升級前/後一致性驗證 (唯讀)。
.DESCRIPTION
    擷取 host / cluster / 服務 / 版本快照並可比對前後差異，用於升級前建立
    baseline、升級後驗證一致性。純唯讀，不改動環境。

    工作模式：
      -Mode Capture  擷取目前狀態存成 JSON 快照 (升級前先跑一次)。
      -Mode Compare  讀入 baseline 快照，與目前狀態比對，標記差異/異常。
.PARAMETER Environment
    uat | test | prod。
.PARAMETER Mode
    Capture | Compare。
.PARAMETER SnapshotPath
    Capture 模式：輸出檔；Compare 模式：要比對的 baseline 檔。
.EXAMPLE
    # 升級前
    .\Compare-VCFState.ps1 -Environment prod -Mode Capture -SnapshotPath .\before-prod.json
    # 升級後
    .\Compare-VCFState.ps1 -Environment prod -Mode Compare -SnapshotPath .\before-prod.json
.NOTES
    需要：VMware.PowerCLI、SecretManagement。REST 路徑以官方 API 文件為準。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][ValidateSet('Capture','Compare')][string]$Mode,
    [Parameter(Mandatory)][string]$SnapshotPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '..\..\..\lib\VCFGuardrails.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '..\..\..\lib\VCFConnect.psm1')    -Force

function Get-VCFStateSnapshot {
    param($Env)
    $snap = [ordered]@{
        Environment = $Env.Name
        CapturedAt  = (Get-Date).ToString('o')
        Components  = @{}
        Hosts       = @()
        Clusters    = @()
        Services    = @()
    }

    # --- 元件版本 (REST) ---
    try {
        $sddc = Get-VCFRestToken -Environment $Env -Service SDDC
        $mgrs = Invoke-RestMethod -Method Get -Uri "$($sddc.BaseUri)/v1/sddc-managers" -Headers $sddc.Header -SkipCertificateCheck
        $snap.Components['SDDCManager'] = (@($mgrs.elements)[0]).version
    } catch { $snap.Components['SDDCManager'] = "ERROR: $($_.Exception.Message)" }

    try {
        $nsx = Get-VCFRestToken -Environment $Env -Service NSX
        $nv  = Invoke-RestMethod -Method Get -Uri "$($nsx.BaseUri)/api/v1/node/version" -Headers $nsx.Header -SkipCertificateCheck
        $snap.Components['NSX'] = if ($nv.PSObject.Properties['node_version']) { $nv.node_version } elseif ($nv.PSObject.Properties['product_version']) { $nv.product_version } else { "$nv" }
    } catch { $snap.Components['NSX'] = "ERROR: $($_.Exception.Message)" }

    # --- vCenter / hosts / clusters / 服務 (PowerCLI) ---
    Connect-VCFvCenter -Environment $Env | Out-Null
    foreach ($vc in $global:DefaultVIServers) {
        $snap.Components["vCenter:$($vc.Name)"] = $vc.Version
    }
    foreach ($h in (Get-VMHost | Sort-Object Name)) {
        $snap.Hosts += [ordered]@{
            Name = $h.Name; ConnectionState = "$($h.ConnectionState)"; PowerState = "$($h.PowerState)"
            Version = $h.Version; Build = $h.Build
        }
        # 主要服務狀態 (ntpd / TSM-SSH 等)
        foreach ($svc in (Get-VMHostService -VMHost $h | Where-Object { $_.Key -in @('ntpd','TSM-SSH','vpxa') })) {
            $snap.Services += [ordered]@{ Host = $h.Name; Service = $svc.Key; Running = $svc.Running }
        }
    }
    foreach ($c in (Get-Cluster | Sort-Object Name)) {
        $snap.Clusters += [ordered]@{
            Name = $c.Name; HAEnabled = $c.HAEnabled; DrsEnabled = $c.DrsEnabled
            HostCount = @(Get-VMHost -Location $c).Count
        }
    }
    return $snap
}

try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host "[HealthCheck] Mode=$Mode (唯讀)" -ForegroundColor Cyan

    $current = Get-VCFStateSnapshot -Env $env

    if ($Mode -eq 'Capture') {
        $current | ConvertTo-Json -Depth 8 | Out-File $SnapshotPath -Encoding UTF8
        Write-Host "已擷取狀態快照：$SnapshotPath" -ForegroundColor Green
        Write-Host ("  Hosts=$($current.Hosts.Count)  Clusters=$($current.Clusters.Count)  Components=$($current.Components.Count)")
    }
    else {
        if (-not (Test-Path $SnapshotPath)) { throw "找不到 baseline 快照：$SnapshotPath" }
        $base = Get-Content $SnapshotPath -Raw | ConvertFrom-Json
        $diffs = [System.Collections.Generic.List[object]]::new()

        # 元件版本比對
        foreach ($k in $current.Components.Keys) {
            $before = if ($base.Components.PSObject.Properties[$k]) { $base.Components.$k } else { '(無)' }
            $after  = $current.Components[$k]
            if ("$before" -ne "$after") {
                $diffs.Add([pscustomobject]@{ Type='Component'; Item=$k; Before=$before; After=$after; Note='版本變更 (升級預期)' })
            }
        }
        # Host 狀態比對
        $beforeHosts = @{}; foreach ($h in $base.Hosts) { $beforeHosts[$h.Name] = $h }
        foreach ($h in $current.Hosts) {
            if (-not $beforeHosts.ContainsKey($h.Name)) {
                $diffs.Add([pscustomobject]@{ Type='Host'; Item=$h.Name; Before='(無)'; After='存在'; Note='新增主機?' }); continue
            }
            $b = $beforeHosts[$h.Name]
            if ($b.ConnectionState -ne $h.ConnectionState -or $h.ConnectionState -ne 'Connected') {
                $diffs.Add([pscustomobject]@{ Type='Host'; Item=$h.Name; Before=$b.ConnectionState; After=$h.ConnectionState; Note='連線狀態異常需檢查' })
            }
        }
        # 缺失主機
        foreach ($name in $beforeHosts.Keys) {
            if (-not ($current.Hosts | Where-Object Name -eq $name)) {
                $diffs.Add([pscustomobject]@{ Type='Host'; Item=$name; Before='存在'; After='(消失)'; Note='主機消失，務必查明' })
            }
        }

        Write-Host "`n========== 升級前/後比對結果 ==========" -ForegroundColor Cyan
        if ($diffs.Count -eq 0) {
            Write-Host "無差異：狀態一致。" -ForegroundColor Green
        } else {
            $diffs | Format-Table Type, Item, Before, After, Note -AutoSize | Out-Host
            $bad = @($diffs | Where-Object Note -match '異常|消失').Count
            if ($bad -gt 0) { Write-Host "發現 $bad 項需人工確認的異常。" -ForegroundColor Red }
            else { Write-Host "差異皆為升級預期 (版本提升)。" -ForegroundColor Yellow }
        }
    }
}
catch {
    Write-Error "HealthCheck 失敗：$($_.Exception.Message)"
    throw
}
finally {
    Disconnect-VCFAll
}
