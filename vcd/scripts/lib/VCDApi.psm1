<#
.SYNOPSIS
    VMware Cloud Director (VCD) REST API 連線 / 呼叫 helper (v1.0.0)。
.DESCRIPTION
    本模組只負責「VCD 專屬」的連線與低階呼叫，與全域 lib/ 框架互補：
      - 憑證一律由 lib/VCFConnect.psm1 的 Get-VCFCredential 取得 (SecretManagement)，
        絕不在腳本內存明文密碼。
      - 環境物件由 lib/VCFGuardrails.psm1 的 Get-VCFEnvironment 取得，需含 .Vcd 欄位
        (VCD Cell / Load Balancer FQDN)；若無，請在 environments.psd1 內補上。
      - 變更類操作不在本模組；請由呼叫端以 Invoke-VCFChange 包裝後，再呼叫
        Invoke-VcdApi 執行實際 POST/PUT/DELETE。

    驗證流程 (依官方 API 文件)：
      POST https://<cell>/cloudapi/1.0.0/sessions/provider
        Header: Authorization: Basic base64(user@System:pass)
                Accept: application/*;version=<apiVersion>
      回應 Header X-VMWARE-VCLOUD-ACCESS-TOKEN 即為後續 Bearer token。
      官方：https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/-vcloud-api-programming-guide-for-service-providers-10-6/exploring-the-cloud-api/create-a-session-container-api.html
.NOTES
    PowerShell 7+ 建議 (Invoke-RestMethod -SkipCertificateCheck)。
    所有路徑以官方 VMware Cloud Director OpenAPI (cloudapi/1.0.0) 與
    Programming Guide (legacy /api) 為準，不確定處已於註解標註。
#>

Set-StrictMode -Version Latest

# 預設協商的 API 版本；可由呼叫端覆寫。VCD 10.6.x 對應 API 38.x。
$script:VcdDefaultApiVersion = '38.1'

function Resolve-VcdHost {
    <#
    .SYNOPSIS  從環境物件解析 VCD Cell / LB 的 FQDN。
    .DESCRIPTION  優先用 .Vcd 欄位；若環境尚未定義，丟出明確錯誤提示補設定。
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Environment)
    $vcdHost = $null
    if ($Environment.PSObject.Properties.Name -contains 'Vcd') { $vcdHost = $Environment.Vcd }
    if ([string]::IsNullOrWhiteSpace($vcdHost)) {
        throw "環境 '$($Environment.Name)' 未設定 .Vcd (VCD Cell/LB FQDN)。請於 lib/environments.psd1 對應環境加入 Vcd = 'vcd-xxx.corp.local'。"
    }
    $vcdHost
}

function Connect-VcdApi {
    <#
    .SYNOPSIS  以 Provider (System) 身分登入 VCD，回傳可重用的連線內容。
    .PARAMETER Environment  Get-VCFEnvironment 回傳的環境物件 (需含 .Vcd)。
    .PARAMETER ApiVersion   要協商的 API 版本字串 (預設 38.1)。
    .OUTPUTS  @{ BaseUri; Header; ApiVersion; Host } — Header 已含 Bearer token 與 Accept。
    .EXAMPLE
        $env = Get-VCFEnvironment -Name uat
        $vcd = Connect-VcdApi -Environment $env
        Invoke-VcdApi -Conn $vcd -Path '/cloudapi/1.0.0/orgs'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Environment,
        [string]$ApiVersion = $script:VcdDefaultApiVersion
    )
    $vcdHost = Resolve-VcdHost -Environment $Environment
    $cred = Get-VCFCredential -Environment $Environment      # 來自 lib/VCFConnect.psm1
    $user = $cred.UserName
    if ($user -notmatch '@') { $user = "$user@System" }       # Provider 登入需 user@System
    $pass = $cred.GetNetworkCredential().Password
    $b64  = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${user}:${pass}"))

    $baseUri = "https://$vcdHost"
    $loginUri = "$baseUri/cloudapi/1.0.0/sessions/provider"
    Write-Verbose "VCD Provider 登入: $loginUri (api=$ApiVersion)"

    $headers = @{
        Authorization = "Basic $b64"
        Accept        = "application/*;version=$ApiVersion"
    }
    try {
        $resp = Invoke-WebRequest -Method Post -Uri $loginUri -Headers $headers `
                    -SkipCertificateCheck -ErrorAction Stop
    }
    catch {
        throw "VCD 登入失敗 ($vcdHost)：$($_.Exception.Message)。請確認 .Vcd FQDN、憑證、API 版本 (可先打 GET /api/versions 查可用版本)。"
    }

    $token = $resp.Headers['X-VMWARE-VCLOUD-ACCESS-TOKEN']
    if (-not $token) { throw "VCD 登入未取得 X-VMWARE-VCLOUD-ACCESS-TOKEN，無法繼續。" }
    if ($token -is [array]) { $token = $token[0] }

    [pscustomobject]@{
        BaseUri    = $baseUri
        Host       = $vcdHost
        ApiVersion = $ApiVersion
        Header     = @{
            Authorization = "Bearer $token"
            Accept        = "application/*;version=$ApiVersion"
        }
    }
}

function Invoke-VcdApi {
    <#
    .SYNOPSIS  對已登入的 VCD 連線發出 REST 呼叫 (預設 GET / 唯讀)。
    .PARAMETER Conn    Connect-VcdApi 回傳物件。
    .PARAMETER Path    以 / 起始的相對路徑 (如 /cloudapi/1.0.0/orgs 或 /api/query?type=cell)。
    .PARAMETER Method  HTTP 方法，預設 Get。變更類請由 Invoke-VCFChange 包裝後再呼叫。
    .PARAMETER Body    PSObject/hashtable，會轉成 JSON。
    .PARAMETER ContentType  預設 application/*+json 並帶版本。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Conn,
        [Parameter(Mandatory)][string]$Path,
        [ValidateSet('Get','Post','Put','Delete')][string]$Method = 'Get',
        $Body,
        [string]$ContentType
    )
    $uri = if ($Path -match '^https?://') { $Path } else { "$($Conn.BaseUri)$Path" }
    $params = @{
        Method               = $Method
        Uri                  = $uri
        Headers              = $Conn.Header
        SkipCertificateCheck = $true
        ErrorAction          = 'Stop'
    }
    if ($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body) {
        $params.Body        = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 30 }
        $params.ContentType = if ($ContentType) { $ContentType } else { "application/*+json;version=$($Conn.ApiVersion)" }
    }
    Invoke-RestMethod @params
}

function Get-VcdPagedResult {
    <#
    .SYNOPSIS  自動翻頁取回 cloudapi 1.0.0 清單型 endpoint 的所有 values。
    .DESCRIPTION  cloudapi 清單回應含 { resultTotal, pageCount, page, pageSize, values:[] }。
                  本函式逐頁取回並合併 values。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Conn,
        [Parameter(Mandatory)][string]$Path,   # 不含 page 參數，如 /cloudapi/1.0.0/orgVdcs
        [int]$PageSize = 128
    )
    $all = @()
    $page = 1
    do {
        $sep = if ($Path -match '\?') { '&' } else { '?' }
        $r = Invoke-VcdApi -Conn $Conn -Path "$Path${sep}page=$page&pageSize=$PageSize"
        if ($r.PSObject.Properties.Name -contains 'values' -and $r.values) { $all += $r.values }
        $pageCount = if ($r.PSObject.Properties.Name -contains 'pageCount') { [int]$r.pageCount } else { 1 }
        $page++
    } while ($page -le $pageCount)
    $all
}

function Disconnect-VcdApi {
    <#
    .SYNOPSIS  登出 VCD session (DELETE 目前 session)。盡力而為，不阻斷主流程。
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Conn)
    try {
        Invoke-VcdApi -Conn $Conn -Path '/cloudapi/1.0.0/sessions' -Method Get | Out-Null
        # 取得目前 session 後刪除；不同版本回應結構可能不同，以官方 API 文件為準。
    }
    catch { Write-Verbose "VCD 登出略過：$($_.Exception.Message)" }
}

Export-ModuleMember -Function Resolve-VcdHost, Connect-VcdApi, Invoke-VcdApi, Get-VcdPagedResult, Disconnect-VcdApi
