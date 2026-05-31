# =====================================================================
# 環境清單範本 (PowerShell Data File)
# 用法：複製成 environments.psd1 並填入你的實際環境。
#       environments.psd1 已被 .gitignore 排除，不會 commit（避免外洩）。
#
# Tier 決定安全護欄嚴格度：
#   UAT  / TEST → 允許變更，單次確認
#   PROD        → 預設唯讀；變更需二次確認 + 變更單號 + 強制先 dry-run
#
# 認證一律走 SecretManagement（見 lib/README.md），這裡只放「祕密名稱」，
# 絕不放明文密碼。
# =====================================================================
@{
    uat = @{
        Tier                = 'UAT'
        SddcManager         = 'sddc-uat.lab.local'
        vCenter             = 'vc-uat.lab.local'
        Nsx                 = 'nsx-uat.lab.local'
        HcxManager          = 'hcx-uat.lab.local'
        # SecretManagement 內的祕密名稱 (PSCredential)
        CredentialName      = 'vcf-uat'
        AllowChange         = $true
        RequireChangeTicket = $false
        RequireBackup       = $false
    }

    test = @{
        Tier                = 'TEST'
        SddcManager         = 'sddc-test.corp.local'
        vCenter             = 'vc-test.corp.local'
        Nsx                 = 'nsx-test.corp.local'
        HcxManager          = 'hcx-test.corp.local'
        CredentialName      = 'vcf-test'
        AllowChange         = $true
        RequireChangeTicket = $false
        RequireBackup       = $true
    }

    prod = @{
        Tier                = 'PROD'
        SddcManager         = 'sddc.corp.local'
        vCenter             = 'vc.corp.local'
        Nsx                 = 'nsx.corp.local'
        HcxManager          = 'hcx.corp.local'
        CredentialName      = 'vcf-prod'
        AllowChange         = $false   # 預設禁止變更；需顯式以 -ForceProdChange 提權
        RequireChangeTicket = $true    # 變更必須提供變更單號
        RequireBackup       = $true    # 變更前必須確認已備份
    }
}
