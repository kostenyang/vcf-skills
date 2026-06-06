# CHANGELOG

依日期記錄 skill 與技術文件的變動。版本與相容性以 Broadcom 官方文件為準。

## 2026-06-06 — skill 改名加 -ppt 後綴

- 5 個 skill 全部改名加 `-ppt` 後綴，讓「做簡報用」的 skill 一眼可辨：
  - `vcf-9` → `vcf-9-ppt`、`vcf-521` → `vcf-521-ppt`、`vcf-upgrade` → `vcf-upgrade-ppt`、
    `vcd` → `vcd-ppt`、`hcx` → `hcx-ppt`（以 `git mv` 改名，保留歷史）。
- 同步更新：各 `SKILL.md` 的 `name:` 欄位與彼此交叉引用、README（表格/目錄樹/安裝指令/關係）、
  `docs/` 與 `MAINTENANCE.md` 內的 skill 引用、runbook 與 SKILL 範例中的 `./<skill>/` 執行路徑。
- `lib/`（共用框架，非 skill）維持原名。

## 2026-05-31 — 實戰操作層（v3）

- 將 skill 從「知識型」升級為「實戰操作型」，可在真實環境執行。
- 新增共用安全框架 `lib/`：
  - `environments.example.psd1`：UAT/TEST/PROD 環境分級範本。
  - `VCFGuardrails.psm1`：`Invoke-VCFChange` 依 Tier 分級護欄（PROD 二次確認/單號/備份/dry-run）。
  - `VCFConnect.psm1`：vCenter/SDDC/NSX/HCX 連線，憑證走 SecretManagement 不落地。
- 用 workflow 為 5 個主題產生 **38 支腳本 + 14 份 runbook**（PowerCLI/Python/bash）：
  - 每主題含 `scripts/{healthcheck,precheck,change}/` 與 `runbooks/`。
  - 15 支變更腳本全部套用 `Invoke-VCFChange` 護欄。
  - 各 `SKILL.md` 新增「實戰操作 (Operations)」章節。
- `.gitignore` 排除 `environments.psd1` 等機密；README 新增操作與安全分級說明。

## 2026-05-31 — 上網研究優化（v2）

- 用 workflow 讓 agent 實際上網（Broadcom TechDocs + VMware blog，98 次查詢）重寫全部 5 個 skill 與 docs。
- 重大更新與校正：
  - **VCF 9**：補上 9.0/9.0.1/9.0.2/9.1 版本時間線與 build 號（9.1.0.0 GA 2026-05-12 Build 25377994）、
    Fleet→Instance→Domain 階層、VCF Operations/Automation 單一實例、VCF Identity Broker、
    Enhanced NVMe Memory Tiering、ESX Live Patching、vSphere Elastic Provisioning 等。
  - **VCF 5.2.1**：補上完整 BOM（vCenter 8.0 U3c / ESXi 8.0 U3b / NSX 4.2.1 等）、
    校正「baseline→image 轉換」其實要到 5.2.2、Depot 驗證變更 KB 390098、SSH 預設關閉 KB 86230。
  - **HCX**：校正 **WAN Optimization 已於 4.11.3 棄用、4.11.4 移除**、最新版 4.11.x、
    EOS 時程、VCF Solution Licensing 自動繼承 Enterprise、並行規模 300/600/1000。
  - **升級**：補上 9.1 Upgrade Planning Tool、VCF Management Services、升級順序、
    vIDM→VIDB 無遷移路徑、principal storage 擴展 vSAN/FC/NFS、VCD 不支援等校正。
  - **VCD**：補強多層租戶、IP Spaces、Data Center Group、CSE 與最新版本資訊。

## 2026-05-31 — 初版

- 新增 5 個 Claude Code skill：`vcf-9`、`vcd`、`hcx`、`vcf-521`、`vcf-upgrade`。
- 每個主題含 `SKILL.md` + `references/` 技術 md。
- 新增 `docs/` 完整技術文件（可獨立閱讀）。
- 新增維護機制：`MAINTENANCE.md` + `scripts/vcf-docs-generate.js`（文件半自動重生 workflow）。
- 內容依 2026-05 期間 Broadcom TechDocs / Release Notes / 官方部落格整理。
  - VCF 9.0（GA 2025-06-17）、VCF 9.1、VCD 10.6/10.6.1、HCX、VCF 5.2.1、升級路徑。
