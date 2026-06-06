<#
.SYNOPSIS
    提交 HCX Bulk / RAV 遷移 (大規模變更)，指定切換窗，監控並可執行 cutover。
.DESCRIPTION
    *** 大規模操作，PROD 嚴格護欄 ***
    流程：
      1) 讀入要遷移的 VM 清單 (-VMNames 或 -VMListFile)。
      2) (建議) 先呼叫 validate 驗證相容性。
      3) 以 Invoke-VCFChange 包裝提交 migrations action=start，帶切換窗
         (schedule) 與遷移類型 (Bulk / RAV)。
      4) -Monitor 開關可在提交後輪詢狀態直到複製完成 / 進入待切換。
      5) cutover：Bulk 於切換窗自動重啟切換；RAV 為序列 vMotion 切換。

    HCX REST (以官方 API 文件為準)：
      POST /hybridity/api/migrations?action=validate
      POST /hybridity/api/migrations?action=start
      POST /hybridity/api/migrations?action=query   (監控)
      https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11.html
.PARAMETER Environment
    來源端 uat | test | prod。
.PARAMETER MigrationType
    Bulk | RAV。
.PARAMETER VMNames
    要遷移的 VM 名稱陣列 (與 -VMListFile 擇一)。
.PARAMETER VMListFile
    每行一個 VM 名稱的清單檔。
.PARAMETER ServiceMeshName
    承載遷移的 Service Mesh。
.PARAMETER DestinationComputeName / DestinationDatastore / DestinationFolder / DestinationNetwork
    目的端落點。
.PARAMETER SwitchoverStart
    切換窗開始時間 (DateTime)，未提供則建立後依預設行為。
.PARAMETER SwitchoverEnd
    切換窗結束時間 (DateTime)。
.PARAMETER Monitor
    提交後輪詢狀態。
.PARAMETER ForceProdChange / ChangeTicket
    PROD 提權與變更單號。
.EXAMPLE
    ./Submit-HcxMigration.ps1 -Environment uat -MigrationType RAV -VMNames app-01,app-02 `
        -ServiceMeshName SM-UAT -DestinationComputeName Cluster-Dst -DestinationDatastore DS-Dst `
        -DestinationNetwork 'app-seg' -SwitchoverStart '2026-06-01 22:00' -SwitchoverEnd '2026-06-01 23:30' -Monitor
.NOTES
    需先 Import-Module lib/VCFGuardrails.psm1, lib/VCFConnect.psm1。
    RAV/Bulk 並行度上限見 KB 373010；大規模請分波次並先在 UAT/TEST 驗證。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][ValidateSet('Bulk','RAV')][string]$MigrationType,
    [string[]]$VMNames,
    [string]$VMListFile,
    [Parameter(Mandatory)][string]$ServiceMeshName,
    [Parameter(Mandatory)][string]$DestinationComputeName,
    [Parameter(Mandatory)][string]$DestinationDatastore,
    [string]$DestinationFolder,
    [Parameter(Mandatory)][string]$DestinationNetwork,
    [datetime]$SwitchoverStart,
    [datetime]$SwitchoverEnd,
    [switch]$Monitor,
    [switch]$ForceProdChange,
    [string]$ChangeTicket
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Import-Module (Join-Path $repo 'lib/VCFGuardrails.psm1') -Force
Import-Module (Join-Path $repo 'lib/VCFConnect.psm1')   -Force

function Invoke-Hcx {
    param([string]$Method, [string]$Path, $Body, [hashtable]$Token)
    $uri = "$($Token.BaseUri)/hybridity/api$Path"
    $p = @{ Method = $Method; Uri = $uri; Headers = $Token.Header; ContentType = 'application/json'; SkipCertificateCheck = $true }
    if ($Body) { $p.Body = ($Body | ConvertTo-Json -Depth 14) }
    Invoke-RestMethod @p
}

try {
    # ---- 組 VM 清單 ----
    if ($VMListFile) {
        if (-not (Test-Path $VMListFile)) { throw "找不到清單檔 $VMListFile" }
        $VMNames = Get-Content $VMListFile | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() }
    }
    if (-not $VMNames) { throw "請以 -VMNames 或 -VMListFile 提供要遷移的 VM。" }

    $env = Get-VCFEnvironment -Name $Environment
    $tok = Get-VCFRestToken -Environment $env -Service HCX

    # 遷移類型 -> HCX migrationType 字串 (以官方 API 文件為準)
    $hcxType = if ($MigrationType -eq 'RAV') { 'HCX_REPLICATION_ASSISTED_VMOTION' } else { 'BULK_VMOTION' }

    # 每台 VM 一筆 migration entry
    $entries = foreach ($name in $VMNames) {
        $e = @{
            input = @{
                migrationType = $hcxType
                entity = @{ entityType = 'VirtualMachine'; entityName = $name }
                destination = @{
                    computeName = $DestinationComputeName
                    storage     = @{ datastoreName = $DestinationDatastore }
                    folderName  = $DestinationFolder
                }
                networkMappings = @( @{ sourceNetworkName = $DestinationNetwork; destNetworkName = $DestinationNetwork } )
                serviceMeshName = $ServiceMeshName
            }
        }
        if ($SwitchoverStart) {
            $e.input.schedule = @{
                scheduledFailover = $true
                startYear = $SwitchoverStart.Year;  startMonth = $SwitchoverStart.Month;  startDay = $SwitchoverStart.Day
                startHour = $SwitchoverStart.Hour;  startMinute = $SwitchoverStart.Minute
            }
            if ($SwitchoverEnd) {
                $e.input.schedule.endYear = $SwitchoverEnd.Year; $e.input.schedule.endMonth = $SwitchoverEnd.Month; $e.input.schedule.endDay = $SwitchoverEnd.Day
                $e.input.schedule.endHour = $SwitchoverEnd.Hour; $e.input.schedule.endMinute = $SwitchoverEnd.Minute
            }
        }
        $e
    }
    $payload = @{ items = @($entries) }

    # ---- (建議) 先 validate ----
    Write-Host "`n=== 遷移相容性驗證 (validate) ===" -ForegroundColor Green
    try {
        $v = Invoke-Hcx -Method POST -Path '/migrations?action=validate' -Body $payload -Token $tok
        $hasErr = $false
        foreach ($it in @($v.items)) {
            $errs = @($it.errors)
            if ($errs.Count) { $hasErr = $true; Write-Host ("  [X] {0}: {1}" -f $it.input.entity.entityName, ($errs.message -join '; ')) -ForegroundColor Red }
            else { Write-Host ("  [OK] {0}" -f $it.input.entity.entityName) -ForegroundColor Green }
        }
        if ($hasErr) { throw "validate 發現相容性錯誤，已中止提交 (請先修正)。" }
    } catch {
        Write-Host "  validate 無法執行或回報錯誤：$($_.Exception.Message)" -ForegroundColor Yellow
        throw
    }

    # ---- 提交遷移 (護欄) ----
    Invoke-VCFChange -Environment $env -Impact Change `
        -Description ("提交 {0} 遷移 {1} 台 VM 到 {2} (mesh={3}{4})" -f $MigrationType, $VMNames.Count, $DestinationComputeName, $ServiceMeshName, $(if ($SwitchoverStart) { ", 切換窗 $SwitchoverStart" } else { '' })) `
        -ForceProdChange:$ForceProdChange -ChangeTicket $ChangeTicket `
        -Preview {
            "將提交以下遷移 (dry-run，未實際開始)："
            "  類型      : $MigrationType ($hcxType)"
            "  VM 數量   : $($VMNames.Count)"
            "  VM        : $($VMNames -join ', ')"
            "  目的       : $DestinationComputeName / $DestinationDatastore / net=$DestinationNetwork"
            if ($SwitchoverStart) { "  切換窗     : $SwitchoverStart ~ $SwitchoverEnd" } else { "  切換       : 未排程，依預設行為 (RAV 序列 vMotion / Bulk 重啟切換)" }
            "  目標       : POST /hybridity/api/migrations?action=start"
            "  提醒       : 大規模操作，確認 IX/NE 頻寬與並行度 (KB 373010)。"
        } `
        -Action {
            $r = Invoke-Hcx -Method POST -Path '/migrations?action=start' -Body $payload -Token $tok
            Write-Host "已提交遷移，回應：" -ForegroundColor Green
            $r | ConvertTo-Json -Depth 6 | Write-Host
            $script:submitted = @($r.items)
        }

    # ---- 監控 ----
    if ($Monitor) {
        Write-Host "`n=== 監控遷移進度 (Ctrl+C 可停止監控，遷移仍在背景進行) ===" -ForegroundColor Cyan
        do {
            Start-Sleep -Seconds 30
            $q = Invoke-Hcx -Method POST -Path '/migrations?action=query' -Body @{ filter = @{ } } -Token $tok
            $mine = @($q.items) | Where-Object { $_.migrationInfo.entityName -in $VMNames }
            $done = 0
            foreach ($m in $mine) {
                $st = $m.state
                if ($st -in @('MIGRATED','MIGRATE_COMPLETE','COMPLETED')) { $done++ }
                Write-Host ("  {0,-25} state={1}" -f $m.migrationInfo.entityName, $st)
            }
            Write-Host ("  -- 完成 {0}/{1} --" -f $done, $VMNames.Count) -ForegroundColor DarkGray
        } while ($done -lt $VMNames.Count)
        Write-Host "所有遷移已達完成狀態。請於目的端驗證 VM 開機 / 服務正常後，再清理來源。" -ForegroundColor Green
    } else {
        Write-Host "`n未指定 -Monitor。請以 Get-HcxHealth.ps1 -Environment $Environment 追蹤進行中遷移。" -ForegroundColor Cyan
    }
}
catch {
    Write-Error "提交遷移失敗：$($_.Exception.Message)"
    throw
}
# 本腳本以 REST 操作，未連 vCenter，故不需 Disconnect-VCFAll。
