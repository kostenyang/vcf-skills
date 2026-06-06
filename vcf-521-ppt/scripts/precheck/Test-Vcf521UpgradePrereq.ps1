<#
.SYNOPSIS
    VCF 5.2.1 升級前置檢查 (precheck，唯讀)。
.DESCRIPTION
    升級前統整檢查 (不改動環境)：
      1. Depot / Online Depot 連線與認證 (KB 390098 Depot 驗證變更)。
      2. 目標升級 bundle 是否已下載/可用 (GET /v1/bundles)。
      3. SSH 服務狀態提醒 (KB 86230：5.2 起 ESXi/SDDC 元件 SSH 預設關閉)。
      4. baseline 叢集清單：升 VCF 9 前須全部轉 image，且轉換功能需先升到 5.2.2。
      5. 觸發 SDDC Manager 內建 upgrade precheck (POST /v1/system/prechecks) 並回報。
    API 路徑以官方文件為準：
      https://developer.broadcom.com/xapis/vmware-cloud-foundation-api/latest/
.PARAMETER Environment
    目標環境名稱：uat | test | prod。
.PARAMETER RunSddcPrecheck
    觸發 SDDC Manager 內建系統 precheck (POST，屬唯讀型檢查作業，但會在系統建立任務)。
.EXAMPLE
    ./Test-Vcf521UpgradePrereq.ps1 -Environment test
.EXAMPLE
    ./Test-Vcf521UpgradePrereq.ps1 -Environment uat -RunSddcPrecheck
.NOTES
    本腳本以盤點/檢查為主；-RunSddcPrecheck 會建立 SDDC Manager 端 precheck 任務
    (官方支援的升級前檢查，不變更組態)。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [switch]$RunSddcPrecheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot/../../../lib/VCFGuardrails.psm1" -Force
Import-Module "$PSScriptRoot/../../../lib/VCFConnect.psm1"   -Force

function Invoke-VcfGet {
    param($Tok, [string]$Path)
    try { return Invoke-RestMethod -Method Get -Uri "$($Tok.BaseUri)$Path" -Headers $Tok.Header -SkipCertificateCheck }
    catch { Write-Host "  [略過] $Path：$($_.Exception.Message)" -ForegroundColor DarkYellow; return $null }
}

try {
    $env = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    Write-Host 'Precheck 模式：唯讀 / 檢查 (不變更組態)' -ForegroundColor DarkGray
    $tok = Get-VCFRestToken -Environment $env -Service SDDC

    Write-Host "`n== 1. Depot 連線 (KB 390098) ==" -ForegroundColor Cyan
    $depot = Invoke-VcfGet -Tok $tok -Path '/v1/system/settings/depot'
    if ($depot) {
        $depot | ConvertTo-Json -Depth 4 | Out-Host
        Write-Host '  提醒：KB 390098 — Broadcom 已變更 Depot 驗證方式，' -ForegroundColor DarkYellow
        Write-Host '        請確認已設定有效的下載 token / Broadcom 帳號繫結。' -ForegroundColor DarkYellow
    } else {
        Write-Host '  [警告] 無法取得 Depot 設定，請確認 Online/Offline Depot 已正確設定。' -ForegroundColor Yellow
    }

    Write-Host '== 2. 可用 / 已下載 bundle ==' -ForegroundColor Cyan
    $bundles = (Invoke-VcfGet -Tok $tok -Path '/v1/bundles').elements
    if ($bundles) {
        $bundles |
            Select-Object id, type,
                @{n='version';e={$_.version}},
                @{n='downloadStatus';e={$_.downloadStatus}} |
            Sort-Object downloadStatus, type | Format-Table -AutoSize | Out-Host
        $pending = $bundles | Where-Object { $_.downloadStatus -and $_.downloadStatus -ne 'SUCCESSFUL' }
        if ($pending) {
            Write-Host "  [注意] 有 $($pending.Count) 個 bundle 尚未完成下載。" -ForegroundColor Yellow
        }
    } else {
        Write-Host '  [注意] 目前沒有可用 bundle，請先於 SDDC Manager 觸發下載。' -ForegroundColor Yellow
    }

    Write-Host '== 3. SSH 狀態 (KB 86230) ==' -ForegroundColor Cyan
    Write-Host '  提醒：VCF 5.2 起 ESXi / 多數元件 SSH 預設關閉 (KB 86230)。' -ForegroundColor DarkYellow
    Write-Host '        若升級流程或支援需暫時啟用，請於完成後立即關閉並記錄。' -ForegroundColor DarkYellow

    Write-Host '== 4. baseline 叢集 (升 9 前須轉 image，轉換需 5.2.2) ==' -ForegroundColor Cyan
    Write-Host '  請另執行 healthcheck/Get-Vcf521VlcmMode.ps1 取得完整 baseline 叢集清單。' -ForegroundColor DarkGray

    if ($RunSddcPrecheck) {
        Write-Host '== 5. 觸發 SDDC Manager 內建 precheck ==' -ForegroundColor Cyan
        $body = @{ resources = @(@{ resourceType = 'SDDC_MANAGER' }) } | ConvertTo-Json -Depth 5
        try {
            $task = Invoke-RestMethod -Method Post -Uri "$($tok.BaseUri)/v1/system/prechecks" `
                -Headers $tok.Header -Body $body -ContentType 'application/json' -SkipCertificateCheck
            Write-Host "  已建立 precheck 任務：$($task.id)  狀態：$($task.status)" -ForegroundColor Green
            Write-Host '  可於 SDDC Manager UI 或 GET /v1/system/prechecks/{id} 追蹤結果。' -ForegroundColor DarkGray
        } catch {
            Write-Host "  [略過] 觸發 precheck 失敗：$($_.Exception.Message)" -ForegroundColor DarkYellow
            Write-Host '  precheck body/resourceType 以官方 API 文件為準。' -ForegroundColor DarkGray
        }
    }

    Write-Host "`nPrecheck 盤點完成。請於 UAT/TEST 先行驗證後再進 PROD。" -ForegroundColor Green
}
catch {
    Write-Error "Precheck 失敗：$($_.Exception.Message)"
    throw
}
