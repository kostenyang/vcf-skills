<#
.SYNOPSIS
    分階段觸發 VCF 升級 (SDDC Manager -> NSX -> vCenter -> ESX)，每階段輪詢狀態並設驗證 gate。
.DESCRIPTION
    這是「會改動環境」的腳本：每個階段的升級觸發都包在 Invoke-VCFChange 內，
    具備 -Preview (dry-run) 與 -Action；PROD 由框架強制護欄 (二次確認/單號/備份)。

    本腳本僅「觸發官方升級工作流程並輪詢」，不取代官方升級流程，亦不自行實作
    升級邏輯。實際升級由 SDDC Manager 依官方流程執行。階段順序固定：
      VCF Operations / Fleet (UI) -> SDDC Manager -> NSX -> vCenter -> ESX
    本腳本涵蓋 SDDC Manager / NSX / vCenter / ESX 四個可由 API 觸發的階段；
    VCF Operations / Fleet 階段請依官方於 VCF Operations 介面先行完成。

    強烈建議：每階段之間以 healthcheck (Compare-VCFState.ps1) 做 gate 驗證。
.PARAMETER Environment
    uat | test | prod。
.PARAMETER DomainId
    要升級的 Workload Domain id (由 /v1/domains 取得)。
.PARAMETER Stage
    SDDC | NSX | VCENTER | ESX | ALL (依序執行)。
.PARAMETER BundleId
    該階段使用的升級 bundle id (由 /v1/bundles 或 /v1/upgradables 取得)。
    Stage=ALL 時請改用 -BundleMap 指定各階段 bundle。
.PARAMETER BundleMap
    Hashtable，Stage=ALL 時各階段對應 bundle id，例 @{ SDDC='id1'; NSX='id2'; VCENTER='id3'; ESX='id4' }。
.PARAMETER ForceProdChange
    PROD 提權旗標 (傳遞給 Invoke-VCFChange)。
.PARAMETER ChangeTicket
    PROD 變更單號。
.EXAMPLE
    # UAT 單階段
    .\Invoke-VCFStagedUpgrade.ps1 -Environment uat -DomainId d-123 -Stage SDDC -BundleId b-abc
.EXAMPLE
    # PROD 全序列 (每階段都會被護欄攔下二次確認)
    .\Invoke-VCFStagedUpgrade.ps1 -Environment prod -DomainId d-1 -Stage ALL `
        -BundleMap @{SDDC='b1';NSX='b2';VCENTER='b3';ESX='b4'} -ForceProdChange -ChangeTicket CHG0012345
.NOTES
    REST 路徑以官方 SDDC Manager Public API 文件為準：
      POST /v1/upgrades            觸發升級 (回傳 task)
      GET  /v1/upgrades/{id}       輪詢升級狀態
      GET  /v1/upgradables         可升級候選
    https://developer.broadcom.com/  (VCF API Reference)
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$DomainId,
    [Parameter(Mandatory)][ValidateSet('SDDC','NSX','VCENTER','ESX','ALL')][string]$Stage,
    [string]$BundleId,
    [hashtable]$BundleMap,
    [switch]$ForceProdChange,
    [string]$ChangeTicket,
    [int]$PollSeconds = 30,
    [int]$MaxPollMinutes = 240
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '..\..\..\lib\VCFGuardrails.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '..\..\..\lib\VCFConnect.psm1')    -Force

# resourceType 對應官方升級資源型別 (以官方 API 文件為準)
$StageOrder = @('SDDC','NSX','VCENTER','ESX')
$ResourceTypeMap = @{
    SDDC    = 'SDDC_MANAGER'
    NSX     = 'NSX_T_MANAGER'
    VCENTER = 'VCENTER'
    ESX     = 'ESX_HOST'
}

function Invoke-StageUpgrade {
    param($Env, $Sddc, [string]$StageName, [string]$Bundle)

    if ([string]::IsNullOrWhiteSpace($Bundle)) {
        throw "階段 $StageName 未提供 bundle id (請以 -BundleId 或 -BundleMap 指定)。"
    }
    $resType = $ResourceTypeMap[$StageName]

    # 升級 payload (以官方 /v1/upgrades schema 為準)
    $payload = @{
        bundleId           = $Bundle
        resourceType       = $resType
        resourceUpgradeSpecs = @(@{ resourceId = $DomainId; upgradeNow = $true })
    } | ConvertTo-Json -Depth 6

    $taskId = $null
    Invoke-VCFChange -Environment $Env `
        -Description "觸發 $StageName 升級 (domain=$DomainId, bundle=$Bundle)" `
        -Impact 'Change' -ForceProdChange:$ForceProdChange -ChangeTicket $ChangeTicket `
        -Preview {
            "將對 domain '$DomainId' 的 $StageName ($resType) 觸發升級，bundle=$Bundle。" 
            "API: POST $($Sddc.BaseUri)/v1/upgrades"
            "Payload: $payload"
        } `
        -Action {
            $resp = Invoke-RestMethod -Method Post -Uri "$($Sddc.BaseUri)/v1/upgrades" `
                -Headers ($Sddc.Header + @{ 'Content-Type' = 'application/json' }) `
                -Body $payload -SkipCertificateCheck
            $script:LastTaskId = if ($resp.PSObject.Properties['id']) { $resp.id } elseif ($resp.PSObject.Properties['taskId']) { $resp.taskId } else { $null }
            if (-not $script:LastTaskId) { throw "未取得升級 task id；請對照官方 API schema 確認 payload/回應。" }
            Write-Host "  升級 task id = $($script:LastTaskId)" -ForegroundColor Green
        }

    $taskId = $script:LastTaskId
    if (-not $taskId) {
        Write-Host "  (未執行或已取消，略過輪詢)" -ForegroundColor Yellow
        return $false
    }

    # ---- 輪詢狀態 ----
    Write-Host "  輪詢 $StageName 升級狀態 (每 $PollSeconds 秒, 最長 $MaxPollMinutes 分) ..." -ForegroundColor Cyan
    $deadline = (Get-Date).AddMinutes($MaxPollMinutes)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds $PollSeconds
        try {
            $t = Invoke-RestMethod -Method Get -Uri "$($Sddc.BaseUri)/v1/upgrades/$taskId" -Headers $Sddc.Header -SkipCertificateCheck
            $status = if ($t.PSObject.Properties['status']) { $t.status } elseif ($t.PSObject.Properties['state']) { $t.state } else { 'UNKNOWN' }
            Write-Host "    [$StageName] status=$status"
            switch -Regex ($status) {
                'SUCCESS|COMPLETED' { Write-Host "  ✓ $StageName 升級完成。" -ForegroundColor Green; return $true }
                'FAIL|ERROR'        { throw "$StageName 升級失敗 (status=$status)。請查 SDDC Manager UI 與官方 KB。" }
            }
        } catch {
            if ($_.Exception.Message -match '升級失敗') { throw }
            Write-Host "    (輪詢暫時失敗，重試) $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }
    throw "$StageName 升級輪詢逾時 ($MaxPollMinutes 分)。請至 SDDC Manager UI 查 task $taskId。"
}

try {
    $env  = Get-VCFEnvironment -Name $Environment
    Write-VCFBanner -Environment $env
    $sddc = Get-VCFRestToken -Environment $env -Service SDDC

    $stages = if ($Stage -eq 'ALL') { $StageOrder } else { @($Stage) }

    foreach ($s in $stages) {
        $bundle = if ($Stage -eq 'ALL') {
            if (-not $BundleMap -or -not $BundleMap.ContainsKey($s)) { throw "Stage=ALL 需在 -BundleMap 提供 $s 的 bundle id。" }
            $BundleMap[$s]
        } else { $BundleId }

        Write-Host "`n===== 階段: $s =====" -ForegroundColor Magenta
        $done = Invoke-StageUpgrade -Env $env -Sddc $sddc -StageName $s -Bundle $bundle

        if ($done) {
            Write-Host "`n[GATE] 階段 $s 完成。請在進入下一階段前執行健檢驗證：" -ForegroundColor Yellow
            Write-Host "       .\..\healthcheck\Compare-VCFState.ps1 -Environment $Environment -Mode Compare -SnapshotPath <baseline.json>" -ForegroundColor Yellow
            if ($Stage -eq 'ALL' -and $s -ne $StageOrder[-1]) {
                $go = Read-Host "  健檢通過後輸入 yes 進入下一階段，其他則停止"
                if ($go -ne 'yes') { Write-Host "  已於階段 $s 後停止 (依要求)。" -ForegroundColor Yellow; break }
            }
        } else {
            Write-Host "  階段 $s 未執行；停止後續階段。" -ForegroundColor Yellow
            break
        }
    }
}
catch {
    Write-Error "分階段升級失敗：$($_.Exception.Message)"
    throw
}
finally {
    Disconnect-VCFAll
}
