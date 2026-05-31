<#
.SYNOPSIS
    VCF / vCenter / NSX / HCX 連線 helper。
.DESCRIPTION
    憑證一律從 SecretManagement 取得 (見 lib/README.md)，不在腳本內存明文。
    預設以唯讀心態連線；變更操作請搭配 VCFGuardrails 的 Invoke-VCFChange。
.NOTES
    需要模組：VMware.PowerCLI、Microsoft.PowerShell.SecretManagement。
    REST 呼叫 (SDDC Manager / NSX / HCX) 用內建 Invoke-RestMethod，見 Get-VCFRestToken。
#>

Set-StrictMode -Version Latest

function Get-VCFCredential {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Environment)
    $name = $Environment.CredentialName
    if (-not $name) { throw "環境 $($Environment.Name) 未設定 CredentialName。" }
    # 從 SecretManagement 取 PSCredential
    $cred = Get-Secret -Name $name -ErrorAction Stop
    if ($cred -isnot [pscredential]) {
        throw "祕密 '$name' 不是 PSCredential。請以 Set-Secret -Name $name -Secret (Get-Credential) 建立。"
    }
    $cred
}

function Connect-VCFvCenter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Environment,
        [switch]$AllLinked
    )
    Import-Module VMware.PowerCLI -ErrorAction Stop | Out-Null
    $cred = Get-VCFCredential -Environment $Environment
    Write-Host "連線 vCenter: $($Environment.vCenter) [$($Environment.Tier)]" -ForegroundColor Cyan
    Connect-VIServer -Server $Environment.vCenter -Credential $cred -AllLinked:$AllLinked -ErrorAction Stop
}

function Get-VCFRestToken {
    <#
    .SYNOPSIS  取得 SDDC Manager / NSX / HCX 的 REST 存取 token。
    .PARAMETER Service  SDDC | NSX | HCX
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Environment,
        [Parameter(Mandatory)][ValidateSet('SDDC','NSX','HCX')]$Service
    )
    $cred = Get-VCFCredential -Environment $Environment
    $user = $cred.UserName
    $pass = $cred.GetNetworkCredential().Password

    switch ($Service) {
        'SDDC' {
            $uri = "https://$($Environment.SddcManager)/v1/tokens"
            $body = @{ username = $user; password = $pass } | ConvertTo-Json
            $r = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType 'application/json' -SkipCertificateCheck
            return @{ Header = @{ Authorization = "Bearer $($r.accessToken)" }; BaseUri = "https://$($Environment.SddcManager)" }
        }
        'NSX' {
            # NSX 多用 Basic Auth
            $b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${user}:${pass}"))
            return @{ Header = @{ Authorization = "Basic $b64" }; BaseUri = "https://$($Environment.Nsx)" }
        }
        'HCX' {
            $uri = "https://$($Environment.HcxManager)/hybridity/api/sessions"
            $body = @{ username = $user; password = $pass } | ConvertTo-Json
            $r = Invoke-WebRequest -Method Post -Uri $uri -Body $body -ContentType 'application/json' -SkipCertificateCheck
            $tok = $r.Headers['x-hm-authorization']
            return @{ Header = @{ 'x-hm-authorization' = $tok }; BaseUri = "https://$($Environment.HcxManager)" }
        }
    }
}

function Disconnect-VCFAll {
    [CmdletBinding()] param()
    if (Get-Command Disconnect-VIServer -ErrorAction SilentlyContinue) {
        Disconnect-VIServer -Server * -Confirm:$false -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function Get-VCFCredential, Connect-VCFvCenter, Get-VCFRestToken, Disconnect-VCFAll
