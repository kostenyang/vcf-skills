<#
.SYNOPSIS
    觸發 SDDC Manager 獨立升級 (變更操作，走護欄)。
.DESCRIPTION
    在 VCF 升級流程中，SDDC Manager 須先於其他元件升級。本腳本透過
    SDDC Manager Public API (/v1/upgrades) 對 SDDC_MANAGER 資源建立升級任務，
    使用指定的升級 bundle。屬高風險變更，一律包在 Invoke-VCFChange 內並先 dry-run；
    PROD 由框架自動要求備份 / 單號 / 二次確認。
    建議先跑 precheck (Test-Vcf521UpgradePrereq.ps1) 通過後再執行。
    API 路徑以官方文件為準：
      POST /v1/upgrades，body 內含 bundleId 與目標 resource
      https://developer.broadcom.com/xapis/vmware-cloud-foundation-api/latest/
.PARAMETER Environment
    目標環境名稱：uat | test | prod。
.PARAMETER BundleId
    SDDC Manager 升級 bundle id (須已下載完成)。
.PARAMETER ResourceId
    SDDC Manager 資源 id (GET /v1/sddc-manager 取得)。
.PARAMETER ForceProdChange
    PROD 提權旗標 (PROD 必填)。
.PARAMETER ChangeTicket
    變更單號。
.EXAMPLE
    ./Invoke-Vcf521SddcManagerUpgrade.ps1 -Environment test -BundleId <id> -ResourceId <id>
.NOTES
    高風險：請務必先備份 SDDC Manager，並於維護視窗執行。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$BundleId,
    [Parameter(Mandatory)][string]$ResourceId,
    [switch]$ForceProdChange,
    [string]$ChangeTicket
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot/../../../lib/VCFGuardrails.psm1" -Force
Import-Module "$PSScriptRoot/../../../lib/VCFConnect.psm1"   -Force

try {
    $env = Get-VCFEnvironment -Name $Environment
    $tok = Get-VCFRestToken -Environment $env -Service SDDC
    $uri = "$($tok.BaseUri)/v1/upgrades"
    # body 結構以官方 API 文件為準；此為常見 upgrade spec 形態。
    $spec = @{
        bundleId      = $BundleId
        resourceType  = 'SDDC_MANAGER'
        resourceUpgradeSpecs = @(@{ resourceId = $ResourceId })
    }
    $body = $spec | ConvertTo-Json -Depth 6

    Invoke-VCFChange -Environment $env `
        -Description "SDDC Manager 升級 (bundleId=$BundleId)" `
        -Impact 'Destructive' `
        -ForceProdChange:$ForceProdChange `
        -ChangeTicket $ChangeTicket `
        -Preview {
            "將對 $uri 送出 POST 建立 SDDC Manager 升級任務：`n$body`n" +
            "前置：bundle 已下載、precheck 通過、SDDC Manager 已備份。"
        } `
        -Action {
            $task = Invoke-RestMethod -Method Post -Uri $uri -Headers $tok.Header `
                -Body $body -ContentType 'application/json' -SkipCertificateCheck
            Write-Host "已建立升級任務：$($task.id)  狀態：$($task.status)" -ForegroundColor Green
            Write-Host '請於 SDDC Manager UI 或 GET /v1/upgrades/{id} 追蹤；升級期間勿中斷。' -ForegroundColor DarkGray
        }
}
catch {
    Write-Error "觸發 SDDC Manager 升級失敗：$($_.Exception.Message)"
    throw
}
