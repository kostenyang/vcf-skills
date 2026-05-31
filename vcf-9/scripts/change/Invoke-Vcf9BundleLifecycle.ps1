<#
.SYNOPSIS
    VCF 9 變更：觸發 LCM bundle 下載或套用，並輪詢任務狀態 (包在 Invoke-VCFChange 護欄內)。

.DESCRIPTION
    本腳本『只觸發與輪詢』，不做任何超出 API 範圍的環境改動。兩種模式：
      - Download：對指定 bundleId 觸發下載 (PATCH /v1/bundles/{id})，再輪詢 /v1/bundles/{id}
      - Apply   ：對指定 resource 建立 upgrade 任務 (POST /v1/upgrades)，再輪詢 /v1/upgrades/{id}
    兩者皆為『會改動環境』的操作，全程包在 Invoke-VCFChange：
      先 dry-run 預覽，UAT/TEST 單次確認，PROD 需 -ForceProdChange + 單號 + 備份 + 二次確認。
    Apply 視為高風險，Impact 設為 Destructive 以在 PROD 觸發額外 DESTROY 確認。

    REST 路徑與 payload 結構以官方 API 文件為準：
      https://developer.broadcom.com/xapis (VMware Cloud Foundation API Reference — Bundles / Upgrades)
    不同 9.x 維護版欄位可能略有差異，套用前請以該環境 API schema 為準。

.PARAMETER Environment
    uat | test | prod

.PARAMETER Mode
    Download | Apply

.PARAMETER BundleId
    目標 bundle 的 id (Download 模式必填；Apply 模式作為升級 bundle)。

.PARAMETER ResourceType
    Apply 模式：升級對象類型，例如 DOMAIN (以官方 API 為準)。

.PARAMETER ResourceId
    Apply 模式：升級對象 id (例如 domain id)。

.PARAMETER PollSeconds
    輪詢間隔秒數，預設 30。

.PARAMETER MaxPollMinutes
    最長輪詢分鐘數，預設 240。

.PARAMETER ForceProdChange
    PROD 提權旗標。

.PARAMETER ChangeTicket
    變更單號 (PROD 必填)。

.EXAMPLE
    # 觸發下載
    ./Invoke-Vcf9BundleLifecycle.ps1 -Environment test -Mode Download -BundleId <id>

.EXAMPLE
    # 套用升級到某 domain (PROD)
    ./Invoke-Vcf9BundleLifecycle.ps1 -Environment prod -Mode Apply -BundleId <id> `
        -ResourceType DOMAIN -ResourceId <domainId> -ForceProdChange -ChangeTicket CHG0012345

.NOTES
    安全分級：Download=Change；Apply=Destructive。務必先在 UAT/TEST 完整演練。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat', 'test', 'prod')][string]$Environment,
    [Parameter(Mandatory)][ValidateSet('Download', 'Apply')][string]$Mode,
    [Parameter(Mandatory)][string]$BundleId,
    [string]$ResourceType = 'DOMAIN',
    [string]$ResourceId,
    [int]$PollSeconds = 30,
    [int]$MaxPollMinutes = 240,
    [switch]$ForceProdChange,
    [string]$ChangeTicket
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$libRoot = Join-Path $PSScriptRoot '..\..\..\lib'
Import-Module (Join-Path $libRoot 'VCFGuardrails.psm1') -Force
Import-Module (Join-Path $libRoot 'VCFConnect.psm1') -Force

try {
    $env = Get-VCFEnvironment -Name $Environment

    $sddc = Get-VCFRestToken -Environment $env -Service SDDC
    $hdr = $sddc.Header.Clone()
    $hdr['Content-Type'] = 'application/json'
    $base = $sddc.BaseUri

    function Invoke-Sddc {
        param([string]$Method, [string]$Path, $Body)
        $args = @{ Method = $Method; Uri = "$base$Path"; Headers = $hdr; SkipCertificateCheck = $true; ErrorAction = 'Stop' }
        if ($Body) { $args.Body = ($Body | ConvertTo-Json -Depth 8) }
        Invoke-RestMethod @args
    }

    function Wait-Task {
        param([string]$PollPath, [string]$Label)
        $deadline = (Get-Date).AddMinutes($MaxPollMinutes)
        do {
            Start-Sleep -Seconds $PollSeconds
            $st = Invoke-Sddc -Method Get -Path $PollPath
            $status = if ($st.PSObject.Properties.Name -contains 'status') { $st.status }
            elseif ($st.PSObject.Properties.Name -contains 'downloadStatus') { $st.downloadStatus }
            else { 'UNKNOWN' }
            Write-Host ("  [{0}] {1} = {2}" -f (Get-Date -Format HH:mm:ss), $Label, $status)
            if ($status -in @('COMPLETED', 'SUCCESSFUL', 'SUCCEEDED')) { Write-Host "✓ $Label 完成" -ForegroundColor Green; return $true }
            if ($status -in @('FAILED', 'CANCELLED')) { Write-Warning "$Label 失敗 (status=$status)"; return $false }
        } while ((Get-Date) -lt $deadline)
        Write-Warning "$Label 輪詢逾時 ($MaxPollMinutes 分鐘)。請至 SDDC Manager / VCF Operations 確認。"
        return $false
    }

    if ($Mode -eq 'Download') {
        $desc = "觸發 bundle 下載 (bundleId=$BundleId)"
        Invoke-VCFChange -Environment $env -Description $desc -Impact 'Change' `
            -ForceProdChange:$ForceProdChange -ChangeTicket $ChangeTicket `
            -Preview {
            "將對 bundleId=$BundleId 觸發下載 (PATCH /v1/bundles/$BundleId, operation=DOWNLOAD)。"
            '此操作僅下載至 SDDC Manager，不會套用到叢集。'
            '路徑與 payload 以官方 API 文件為準。'
        } `
            -Action {
            # PATCH /v1/bundles/{id}  body 含下載指令 — 結構以官方 API 為準
            Invoke-Sddc -Method Patch -Path "/v1/bundles/$BundleId" -Body @{ bundleDownloadSpec = @{ downloadNow = $true } } | Out-Null
            Write-Host '已送出下載請求，開始輪詢...' -ForegroundColor Yellow
            Wait-Task -PollPath "/v1/bundles/$BundleId" -Label 'Bundle 下載'
        }
    }
    else {
        # Apply
        if (-not $ResourceId) { throw "Apply 模式需提供 -ResourceId (例如 domain id)。" }
        $desc = "套用升級 bundle=$BundleId 至 $ResourceType=$ResourceId"
        Invoke-VCFChange -Environment $env -Description $desc -Impact 'Destructive' `
            -ForceProdChange:$ForceProdChange -ChangeTicket $ChangeTicket `
            -Preview {
            "將建立升級任務：POST /v1/upgrades"
            "  bundleId   = $BundleId"
            "  resource   = $ResourceType / $ResourceId"
            '套用會實際升級元件，過程可能含 host 維護模式輪替與重啟。'
            '強烈建議：已完成備份/快照、已通過 precheck、已選好維護視窗。'
            '路徑與 payload 結構以官方 API 文件為準。'
        } `
            -Action {
            # POST /v1/upgrades — 結構以官方 API 為準
            $body = @{
                bundleId        = $BundleId
                resourceType    = $ResourceType
                resourceUpgradeSpecs = @(@{ resourceId = $ResourceId; resourceType = $ResourceType })
            }
            $resp = Invoke-Sddc -Method Post -Path '/v1/upgrades' -Body $body
            $upId = $resp.id
            if (-not $upId) { throw '未取得升級任務 id，請檢查 API 回應。' }
            Write-Host "已建立升級任務 id=$upId，開始輪詢..." -ForegroundColor Yellow
            Wait-Task -PollPath "/v1/upgrades/$upId" -Label '升級套用'
        }
    }
}
catch {
    Write-Error "Bundle 生命週期操作失敗：$($_.Exception.Message)"
    throw
}
