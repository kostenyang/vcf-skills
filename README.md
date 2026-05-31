# vcf-skills

VMware Cloud Foundation 相關 **Claude Code Skills** 與技術文件集合。
每個主題都包含一個可被 Claude 觸發的 `SKILL.md`，以及 `references/` 下的詳細技術 md。

> 內容以 2026-05 期間的 Broadcom TechDocs / Release Notes / 官方部落格為基礎整理。
> 版本、相容性與授權細節以 Broadcom 官方文件為最終準則。

## Skills 一覽

| Skill | 目錄 | 主題 |
|-------|------|------|
| `vcf-9` | [`vcf-9/`](vcf-9/) | VMware Cloud Foundation 9（含 9.0 與 9.1） |
| `vcd` | [`vcd/`](vcd/) | VMware Cloud Director（多租戶雲端管理） |
| `hcx` | [`hcx/`](hcx/) | VMware HCX（工作負載遷移與混合雲移動） |
| `vcf-521` | [`vcf-521/`](vcf-521/) | VMware Cloud Foundation 5.2.1 |
| `vcf-upgrade` | [`vcf-upgrade/`](vcf-upgrade/) | VCF 升級路徑（Deploy / Converge / Import / Upgrade） |

## 目錄結構

```
vcf-skills/
├── README.md
├── MAINTENANCE.md            # 維護指南：怎麼長期更新這些 skill
├── CHANGELOG.md              # 變動紀錄
├── scripts/
│   └── vcf-docs-generate.js  # 文件半自動重生 workflow (Claude Code)
├── docs/                     # 可獨立閱讀的完整技術文件 (一般 md)
│   ├── VCF9-完整指南.md
│   ├── VCD-完整指南.md
│   ├── HCX-完整指南.md
│   ├── VCF-5.2.1-完整指南.md
│   └── VCF-升級指南.md
├── vcf-9/
│   ├── SKILL.md
│   └── references/{vcf-9.0.md, vcf-9.1.md}
├── vcd/
│   ├── SKILL.md
│   └── references/vcd-10.6.md
├── hcx/
│   ├── SKILL.md
│   └── references/hcx-migration.md
├── vcf-521/
│   ├── SKILL.md
│   └── references/vcf-5.2.1.md
└── vcf-upgrade/
    ├── SKILL.md
    └── references/upgrade-5.2-to-9.0.md
```

## 兩種用途：Skill vs 完整技術文件

| 用途 | 看哪裡 | 說明 |
|------|--------|------|
| 給 Claude 觸發、快速查閱 | `*/SKILL.md` + `*/references/` | Claude Code skill 格式 |
| 給人從頭讀的完整技術文件 | `docs/*.md` | 含目錄、章節、表格、FAQ、checklist |

## 維護

這些 skill 會隨 VCF / VCD / HCX 版本不斷更新。維護策略與更新流程見
[`MAINTENANCE.md`](MAINTENANCE.md)，重點：

- 會過期的內容（版本號、規模數字）集中在 `references/` 與 `docs/`，`SKILL.md` 觸發描述保持穩定。
- `docs/` 可用 `scripts/vcf-docs-generate.js`（workflow）半自動重生。
- 加版號、不刪舊檔；每次更新記 [`CHANGELOG.md`](CHANGELOG.md)。

## 如何安裝為 Claude Code Skills

把各 skill 目錄複製（或 symlink）到你的 Claude skills 目錄，例如：

```bash
# 個人層級 (所有專案可用)
cp -r vcf-9 vcd hcx vcf-521 vcf-upgrade ~/.claude/skills/

# 或專案層級
cp -r vcf-9 vcd hcx vcf-521 vcf-upgrade .claude/skills/
```

每個 `SKILL.md` 都含 YAML frontmatter（`name` + `description`），
Claude 會依 `description` 自動判斷何時觸發該 skill。

## Skill 之間的關係

- 問 **VCF 9 架構/新功能** → `vcf-9`
- 問 **VCF 5.2.1 維運/功能** → `vcf-521`
- 問 **升級流程（5.2→9.0、9.0→9.1、Converge/Import）** → `vcf-upgrade`
- 問 **多租戶雲（VCSP）** → `vcd`
- 問 **遷移 / 上雲 / L2 延伸** → `hcx`

## 實戰操作 (Operations) — 在真實環境執行

這些 skill 不只是知識庫，也含**可在真實 VCF / VCD / HCX 環境執行的腳本**
（healthcheck / precheck / change）與 runbook，全部套用共用安全框架 `lib/`。

### 安全分級（核心）

| Tier | 變更行為 |
|------|----------|
| **UAT**  | 允許變更，單次 `[y/N]` 確認 |
| **TEST** | 允許變更，單次確認；建議先備份 |
| **PROD** | 預設禁止；變更需 `-ForceProdChange` + 變更單號 + 確認備份 + 輸入完整環境名二次確認；破壞性操作再輸入 `DESTROY`；一律先 dry-run |

- 健檢 / precheck = **唯讀**，可直接於 PROD 執行。
- 任何寫入一律經 `Invoke-VCFChange` 護欄（見 [`lib/README.md`](lib/README.md)）。

### 執行方式（重要）

腳本以相對路徑載入 `lib/`，請**在 clone 下來的 repo 根目錄執行**：

```powershell
git clone https://github.com/kostenyang/vcf-skills.git
cd vcf-skills
cp lib/environments.example.psd1 lib/environments.psd1   # 填入你的 uat/test/prod
Set-Secret -Name vcf-prod -Secret (Get-Credential)        # 存憑證 (不落地明文)

# 唯讀健檢
./vcf-9/scripts/healthcheck/Get-Vcf9Health.ps1 -Environment prod
# 變更 (走護欄)
./vcf-9/scripts/change/Set-Vcf9HostMaintenance.ps1 -Environment uat
```

> `environments.psd1`（含真實主機名/帳密對應）已被 `.gitignore` 排除，不會上傳。
> 腳本僅為自動化輔助，**正式環境一律先在 UAT/TEST 演練**，升級/相容性以官方文件為準。

各 skill 的 `scripts/`（healthcheck/precheck/change）與 `runbooks/` 內容，
詳見各 `SKILL.md` 的「實戰操作 (Operations)」章節。

## 授權與免責

僅供技術參考與內部教育用途。所有商標屬 Broadcom / VMware 所有。
正式專案請以 Broadcom 官方 TechDocs、Release Notes 與 Interop Matrix 為準。
