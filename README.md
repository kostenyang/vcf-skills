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

## 授權與免責

僅供技術參考與內部教育用途。所有商標屬 Broadcom / VMware 所有。
正式專案請以 Broadcom 官方 TechDocs、Release Notes 與 Interop Matrix 為準。
