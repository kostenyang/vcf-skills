# Runbook：Catalog 散布 (對外發佈 / 分享給租戶)

將共用 vApp Template / ISO 內容庫散布給租戶：對外發佈 (供其他站點 subscribe) 或分享
給指定 Organization。

> 含「會改動環境」步驟，**一律以 `Invoke-VCFChange` 包裝**。發佈/分享前先確認 catalog
> 同步狀態 (唯讀健檢)，避免散布未就緒的內容。

## 1. 前置條件

- 已完成 `vcd-healthcheck.md` 前置 (SecretManagement 憑證、`environments.psd1` 含 `Vcd`)。
- 來源 catalog 已存在且所有 catalog item 為就緒狀態 (先跑健檢確認)。
- 對外發佈情境：已規劃外部 subscription URL / 密碼策略；目標站點網路可達。
- 分享情境：目標 Organization 已存在。

## 2. 步驟

1. (唯讀) 先確認 catalog 同步狀態：
   ```powershell
   ./vcd-ppt/scripts/healthcheck/Get-VcdCatalogSyncStatus.ps1 -Environment uat
   ```
   確認目標 catalog 的 items 皆就緒，無「非就緒項目」警告。
2. 對外發佈：
   ```powershell
   ./vcd-ppt/scripts/change/Publish-VcdCatalog.ps1 -Environment uat `
       -CatalogName base-templates -Mode PublishExternal
   ```
3. 分享給指定租戶 (唯讀權限)：
   ```powershell
   ./vcd-ppt/scripts/change/Publish-VcdCatalog.ps1 -Environment uat `
       -CatalogName base-templates -Mode ShareToOrg -TargetOrg acme
   ```
4. PROD 範例 (需單號與提權)：
   ```powershell
   ./vcd-ppt/scripts/change/Publish-VcdCatalog.ps1 -Environment prod `
       -CatalogName base-templates -Mode ShareToOrg -TargetOrg acme `
       -ForceProdChange -ChangeTicket CHG0012347
   ```

## 3. 各環境注意事項

| 環境 | 注意事項 |
| --- | --- |
| UAT  | 先驗證 `publishToExternalOrganizations` / `accessControl` 端點在該 API 版本可用 (schema 依版本而異，腳本已標註「以官方 API 文件為準」)。 |
| TEST | 以實際 catalog 名稱與目標 Org 演練；確認分享後租戶確實可見。 |
| PROD | 需 `-ForceProdChange` + `-ChangeTicket`；對外發佈會擴大內容曝光面，務必確認 subscription 安全設定 (密碼、僅限信任站點) 已在變更單載明。 |

## 4. 驗證

- 對外發佈：`Get-VcdCatalogSyncStatus.ps1` 中該 catalog `isPublished` 為 true；於目標站點建立
  subscribed catalog 後可見 item 並完成同步。
- 分享：以目標租戶帳號登入 Tenant Portal，於 Catalogs 可見該共用 catalog (唯讀)。

## 5. 回退

> 取消發佈 / 取消分享屬「改動環境」，請同樣以 `Invoke-VCFChange` 包裝。

- 取消對外發佈：將 `isPublishedExternally` 設為 `false` (對應 action / PUT，以官方 API 文件為準)。
- 取消分享：更新 `accessControl`，移除該 Org 的存取項目。
- 已被遠端 subscribe 的內容：取消發佈不會回收對端已下載副本，需通知對端站點清理。

## 6. 權威來源

- VCD API Programming Guide for Service Providers 10.6：
  https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/-vcloud-api-programming-guide-for-service-providers-10-6.html
- VMware Cloud Director OpenAPI (catalogs)：
  https://developer.broadcom.com/xapis/vmware-cloud-director-openapi/latest/cloudapi/1.0.0/catalogs/
- Global / Distributed Catalogs (10.6 新功能)，見 `references/vcd-10.6.md`。
