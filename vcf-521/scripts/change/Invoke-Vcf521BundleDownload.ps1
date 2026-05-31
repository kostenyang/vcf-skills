<#
.SYNOPSIS
    觸發 VCF 5.2.1 LCM bundle 下載 (變更操作，走護欄)。
.DESCRIPTION
    透過 SDDC Manager Public API (/v1) 觸發指定 bundle 的下載排程
    (PATCH /v1/bundles/{id} 設定 downloadNow=true)。此動作會在環境內建立
    下載任務，故一律包在 Invoke-VCFChange 內，提供 dry-run 預覽；PROD 由框架
    自動加嚴 (二次確認 / 單號 / 備份)。
    API 路徑以官方文件為準：
      https://developer.broadcom.com/xapis/vmware-cloud-foundation-api/latest/
.PARAMETER Environment
    目標環境名稱：uat | test | prod。
.PARAMETER BundleId
    要下載的 bundle id (可先以 precheck 腳本或 GET /v1/bundles 取得)。
.PARAMETER ForceProdChange
    PROD 提權旗標 (PROD 必填)。
.PARAMETER ChangeTicket
    變更單號 (PROD 視環境設定要求)。
.EXAMPLE
    ./Invoke-Vcf521BundleDownload.ps1 -Environment test -BundleId 0d1f...
.EXAMPLE
    ./Invoke-Vcf521BundleDownload.ps1 -Environment prod -BundleId 0d1f... -ForceProdChange -ChangeTicket CHG0012345
.NOTES
    僅觸發『下載』，不套用。套用升級請見對應升級腳本/runbook。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat','test','prod')][string]$Environment,
    [Parameter(Mandatory)][string]$BundleId,
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
    $uri = "$($tok.BaseUri)/v1/bundles/$BundleId"
    $body = @{ bundleDownloadSpec = @{ downloadNow = $true } } | ConvertTo-Json -Depth 5

    Invoke-VCFChange -Environment $env `
        -Description "觸發 LCM bundle 下載 (bundleId=$BundleId)" `
        -Impact 'Change' `
        -ForceProdChange:$ForceProdChange `
        -ChangeTicket $ChangeTicket `
        -Preview {
            "將對 $uri 送出 PATCH，內容：`n$body`n(只觸發下載，不套用升級)"
        } `
        -Action {
            $r = Invoke-RestMethod -Method Patch -Uri $uri -Headers $tok.Header `
                -Body $body -ContentType 'application/json' -SkipCertificateCheck
            Write-Host "已送出下載請求。狀態：$($r.downloadStatus)" -ForegroundColor Green
            Write-Host '可於 SDDC Manager UI 或 GET /v1/bundles/{id} 追蹤進度。' -ForegroundColor DarkGray
        }
}
catch {
    Write-Error "觸發下載失敗：$($_.Exception.Message)"
    throw
}
