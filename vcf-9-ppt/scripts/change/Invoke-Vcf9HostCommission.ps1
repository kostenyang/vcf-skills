<#
.SYNOPSIS
    VCF 9 變更：commission (納管) 或 decommission (移除) ESX host (包在 Invoke-VCFChange 護欄內)。

.DESCRIPTION
    透過 SDDC Manager REST 進行 host commission / decommission，全程包在 Invoke-VCFChange：
      - Commission   ：將閒置 host 納入 SDDC Manager 可用主機池 (POST /v1/hosts)，Impact=Change。
      - Decommission ：將 host 自可用池移除 (DELETE /v1/hosts/{id} 或 POST 移除規格)，
                       Impact=Destructive (PROD 需額外 DESTROY 確認)。
    commission 前可先呼叫驗證 API (validations) — 本腳本在 Preview 中提示，
    實際驗證端點以官方 API 文件為準。

    REST 路徑與 payload 結構以官方 API 文件為準：
      https://developer.broadcom.com/xapis (VMware Cloud Foundation API Reference — Hosts)

.PARAMETER Environment
    uat | test | prod

.PARAMETER Operation
    Commission | Decommission

.PARAMETER HostFqdn
    Commission：要納管的 host FQDN。

.PARAMETER NetworkPoolId
    Commission：指派的 network pool id。

.PARAMETER StorageType
    Commission：儲存類型，例如 VSAN / VSAN_ESA / NFS (以官方 API 為準)，預設 VSAN_ESA。

.PARAMETER HostCredentialName
    Commission：被納管 host 的 root 帳密在 SecretManagement 的祕密名稱
    (PSCredential)。不寫死密碼。

.PARAMETER HostId
    Decommission：要移除的 host id (SDDC Manager 內部 id)。

.PARAMETER ForceProdChange
    PROD 提權旗標。

.PARAMETER ChangeTicket
    變更單號 (PROD 必填)。

.EXAMPLE
    ./Invoke-Vcf9HostCommission.ps1 -Environment test -Operation Commission `
        -HostFqdn esx05.corp.local -NetworkPoolId <poolId> -HostCredentialName esx05-root

.EXAMPLE
    ./Invoke-Vcf9HostCommission.ps1 -Environment prod -Operation Decommission `
        -HostId <hostId> -ForceProdChange -ChangeTicket CHG0012345

.NOTES
    安全分級：Commission=Change；Decommission=Destructive。先在 UAT/TEST 驗證。
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('uat', 'test', 'prod')][string]$Environment,
    [Parameter(Mandatory)][ValidateSet('Commission', 'Decommission')][string]$Operation,
    [string]$HostFqdn,
    [string]$NetworkPoolId,
    [string]$StorageType = 'VSAN_ESA',
    [string]$HostCredentialName,
    [string]$HostId,
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
    $hdr = $sddc.Header.Clone(); $hdr['Content-Type'] = 'application/json'
    $base = $sddc.BaseUri

    function Invoke-Sddc {
        param([string]$Method, [string]$Path, $Body)
        $a = @{ Method = $Method; Uri = "$base$Path"; Headers = $hdr; SkipCertificateCheck = $true; ErrorAction = 'Stop' }
        if ($Body) { $a.Body = ($Body | ConvertTo-Json -Depth 8) }
        Invoke-RestMethod @a
    }

    if ($Operation -eq 'Commission') {
        if (-not $HostFqdn -or -not $NetworkPoolId -or -not $HostCredentialName) {
            throw 'Commission 需 -HostFqdn、-NetworkPoolId 與 -HostCredentialName。'
        }
        # 從 SecretManagement 取被納管 host 的帳密 (不寫死)
        $hostCred = Get-Secret -Name $HostCredentialName -ErrorAction Stop
        if ($hostCred -isnot [pscredential]) { throw "祕密 '$HostCredentialName' 不是 PSCredential。" }

        $desc = "Commission host $HostFqdn (pool=$NetworkPoolId, storage=$StorageType)"
        Invoke-VCFChange -Environment $env -Description $desc -Impact 'Change' `
            -ForceProdChange:$ForceProdChange -ChangeTicket $ChangeTicket `
            -Preview {
            "將把 $HostFqdn 納入 SDDC Manager 可用主機池。"
            "  network pool = $NetworkPoolId"
            "  storage type = $StorageType"
            '建議先執行 host validation API 確認相容性 (端點以官方 API 為準)。'
            'POST /v1/hosts；payload 結構以官方 API 文件為準。'
        } `
            -Action {
            # POST /v1/hosts — commission spec，結構以官方 API 為準
            $body = @(@{
                    fqdn          = $HostFqdn
                    username      = $hostCred.UserName
                    password      = $hostCred.GetNetworkCredential().Password
                    networkPoolId = $NetworkPoolId
                    storageType   = $StorageType
                })
            $resp = Invoke-Sddc -Method Post -Path '/v1/hosts' -Body $body
            Write-Host "已送出 commission 請求。任務 id=$($resp.id)" -ForegroundColor Green
            Write-Host '請於 SDDC Manager / VCF Operations 追蹤任務完成狀態。' -ForegroundColor Yellow
        }
    }
    else {
        if (-not $HostId) { throw 'Decommission 需 -HostId。' }
        $desc = "Decommission host id=$HostId (自可用池移除)"
        Invoke-VCFChange -Environment $env -Description $desc -Impact 'Destructive' `
            -ForceProdChange:$ForceProdChange -ChangeTicket $ChangeTicket `
            -Preview {
            "將把 host id=$HostId 自 SDDC Manager 可用主機池移除。"
            '前提：該 host 不得仍屬於任何 cluster/domain；若仍在使用需先移出。'
            'DELETE /v1/hosts/{id}；確切端點與條件以官方 API 文件為準。'
        } `
            -Action {
            # DELETE /v1/hosts/{id} — 以官方 API 為準
            Invoke-Sddc -Method Delete -Path "/v1/hosts/$HostId" | Out-Null
            Write-Host "已送出 decommission 請求 (host id=$HostId)。" -ForegroundColor Green
            Write-Host '請於 SDDC Manager 追蹤任務完成狀態。' -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Error "Host commission/decommission 失敗：$($_.Exception.Message)"
    throw
}
