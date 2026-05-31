<#
.SYNOPSIS
    VCF 操作安全護欄模組 (UAT / TEST / PROD 分級)。
.DESCRIPTION
    所有「會改動環境」的操作都應透過 Invoke-VCFChange 執行，由本模組依環境
    Tier 套用對應護欄：
      - ReadOnly 動作：永遠放行。
      - Change/Destructive：
          UAT/TEST → 單次 [y/N] 確認。
          PROD     → 預設拒絕 (AllowChange=$false)，需 -ForceProdChange；
                     並要求變更單號 (若 RequireChangeTicket)、確認已備份、
                     輸入完整環境名稱二次確認、且一律先 dry-run 預覽。
    這是唯一準則：寧可多問一次，不要在 PROD 誤改。
#>

Set-StrictMode -Version Latest

function Get-VCFEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Path = (Join-Path $PSScriptRoot 'environments.psd1')
    )
    if (-not (Test-Path $Path)) {
        throw "找不到 $Path。請先複製 environments.example.psd1 為 environments.psd1 並填入你的環境。"
    }
    $all = Import-PowerShellDataFile -Path $Path
    if (-not $all.ContainsKey($Name)) {
        throw "環境 '$Name' 不存在。可用：$($all.Keys -join ', ')"
    }
    $env = $all[$Name]
    $env['Name'] = $Name
    [pscustomobject]$env
}

function Write-VCFBanner {
    param([Parameter(Mandatory)]$Environment)
    $tier = $Environment.Tier
    $color = switch ($tier) { 'PROD' {'Red'} 'TEST' {'Yellow'} default {'Cyan'} }
    Write-Host ("=" * 64) -ForegroundColor $color
    Write-Host (" 環境: {0}  |  Tier: {1}  |  SDDC: {2}" -f $Environment.Name, $tier, $Environment.SddcManager) -ForegroundColor $color
    Write-Host ("=" * 64) -ForegroundColor $color
}

function Invoke-VCFChange {
    <#
    .SYNOPSIS  在護欄下執行一段「會改動環境」的程式碼。
    .EXAMPLE
        Invoke-VCFChange -Environment $env -Description "重啟 SDDC Manager 服務" `
            -Action { Restart-SddcService -Name lcm } `
            -Preview { "將重啟 lcm 服務 (dry-run)" }
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    param(
        [Parameter(Mandatory)]$Environment,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][scriptblock]$Action,
        [scriptblock]$Preview,                       # dry-run 預覽 (回傳將要做的事)
        [ValidateSet('Change','Destructive')][string]$Impact = 'Change',
        [switch]$ForceProdChange,                    # PROD 提權旗標
        [string]$ChangeTicket                        # 變更單號
    )

    Write-VCFBanner -Environment $Environment
    Write-Host "[操作] $Description  (Impact=$Impact)" -ForegroundColor White

    # 1) 一律先預覽 (dry-run)
    if ($Preview) {
        Write-Host "`n--- Dry-run 預覽 ---" -ForegroundColor DarkGray
        & $Preview | Out-Host
        Write-Host "--- 預覽結束 ---`n" -ForegroundColor DarkGray
    }

    # 2) PROD 護欄
    if ($Environment.Tier -eq 'PROD') {
        if (-not $ForceProdChange -or -not $Environment.AllowChange) {
            if (-not $ForceProdChange) {
                throw "[PROD 阻擋] 這是正式環境，變更需明確加上 -ForceProdChange 才能繼續。已中止。"
            }
        }
        if ($Environment.RequireChangeTicket -and [string]::IsNullOrWhiteSpace($ChangeTicket)) {
            throw "[PROD 阻擋] 此環境要求變更單號，請以 -ChangeTicket 提供。已中止。"
        }
        if ($Environment.RequireBackup) {
            $b = Read-Host "[PROD] 是否已完成備份/快照並驗證可回復? 輸入 yes 繼續"
            if ($b -ne 'yes') { throw "[PROD 阻擋] 未確認備份，已中止。" }
        }
        $confirmName = Read-Host "[PROD] 二次確認：請完整輸入環境名稱 '$($Environment.Name)' 以繼續"
        if ($confirmName -ne $Environment.Name) { throw "[PROD 阻擋] 環境名稱不符，已中止。" }
        if ($Impact -eq 'Destructive') {
            $d = Read-Host "[PROD] 這是『破壞性』操作，輸入 DESTROY 以確認"
            if ($d -ne 'DESTROY') { throw "[PROD 阻擋] 未確認破壞性操作，已中止。" }
        }
    }
    else {
        # UAT/TEST：單次確認
        if (-not $Environment.AllowChange) { throw "[$($Environment.Tier) 阻擋] 此環境 AllowChange=`$false。" }
        $ans = Read-Host "在 [$($Environment.Tier)] 執行『$Description』? [y/N]"
        if ($ans -notin @('y','Y')) { Write-Host "已取消。" -ForegroundColor Yellow; return }
    }

    # 3) 執行 (尊重 -WhatIf)
    if ($PSCmdlet.ShouldProcess("$($Environment.Name)", $Description)) {
        $ticketMsg = if ($ChangeTicket) { " [單號:$ChangeTicket]" } else { "" }
        Write-Host "▶ 執行中$ticketMsg ..." -ForegroundColor Green
        & $Action
        Write-Host "✓ 完成：$Description" -ForegroundColor Green
    }
}

Export-ModuleMember -Function Get-VCFEnvironment, Write-VCFBanner, Invoke-VCFChange
