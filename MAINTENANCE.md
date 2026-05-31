# 維護指南 (MAINTENANCE)

VCF / VCD / HCX 版本更新很快，這份文件說明「這些 skill 與技術文件要怎麼長期維護」。
核心原則：**讓會變的東西集中、讓更新可重複、讓每次更新留痕跡**。

---

## 1. 設計原則：分層，讓「會變的」集中

| 檔案 | 變動頻率 | 維護方式 |
|------|----------|----------|
| `*/SKILL.md` | **低**（觸發描述為主） | 盡量穩定，只在主題範圍變動時改 `description` |
| `*/references/*.md` | **中**（版本號、數字、功能） | 新版本主要改這裡 |
| `docs/*.md` | **中**（完整技術文件） | 用 `scripts/vcf-docs-generate.js` 半自動重生 |

> 重點：**版本號、規模數字、最低版本需求**這類「會過期」的內容，集中放在
> `references/` 和 `docs/`，不要散落在 `SKILL.md` 的觸發描述裡。
> 這樣 skill 的觸發行為穩定，更新只動內容。

---

## 2. 版本化（符合「新增檔案可以加版號」原則）

每次有實質更新時：

1. **更新 `CHANGELOG.md`**：記錄日期、改了哪個主題、依據哪個 Release Notes。
2. 重大改版可在檔名加版號保留歷史，例如：
   - `references/vcf-9.1.md` → 出 9.2 時新增 `references/vcf-9.2.md`（**保留** 9.1）。
   - 永遠不刪舊檔，只新增 + 在 README/CHANGELOG 標示最新。
3. Skill 目錄本身維持穩定名稱（`vcf-9`、`vcd`…），避免破壞已安裝的觸發。

---

## 3. 更新流程 (Runbook)

當 Broadcom 發布新版本時：

```text
1. 看 Release Notes / What's New，整理「變動事實」。
2. 改對應的 references/*.md（版本號、數字、新功能）。
3. 半自動重生 docs/：
   - 編輯 scripts/vcf-docs-generate.js 裡對應 TOPIC 的 facts 區塊（貼上新事實）。
   - 在 Claude Code 重跑該 workflow（見下方第 4 節）。
4. 更新 CHANGELOG.md 與 README.md（若最新版本變了）。
5. git commit + push（建議走分支 + PR）。
```

---

## 4. 半自動重生技術文件 (docs/)

`scripts/vcf-docs-generate.js` 是一支 Claude Code **workflow**，會平行為 5 個主題
產生 `docs/*.md`。更新時不必手寫整篇，只要更新事實再重跑：

1. 編輯 `scripts/vcf-docs-generate.js`，找到對應主題的 `facts:` 區塊，貼上新版事實與來源連結。
2. 在 Claude Code 對話輸入（含 `workflow` 關鍵字）：
   > 用 workflow 重跑 scripts/vcf-docs-generate.js 重生 docs，然後 push
3. 把回傳內容寫回 `docs/`，commit。

> 注意：AI 產出需**人工審稿**，特別是版本號 / 最低版本 / 規模數字，務必與官方對照。

---

## 5. 定期檢查（可選自動化）

可在 Claude Code 用 `/schedule` 或 `/loop` 設定定期提醒，例如每月檢查一次：

> 每月 1 號檢查 VCF 9.x / VCD / HCX 是否有新版 Release Notes，有的話彙整變動清單給我。

人工確認後再進入第 3 節的更新流程。

---

## 6. 品質紅線（每次更新必檢）

- [ ] 版本號、日期、規模數字皆對照官方 Release Notes，無臆測。
- [ ] 不確定的內容寫「以 Broadcom 官方文件為準」，不硬填。
- [ ] 每份文件文末「參考來源」連結仍有效。
- [ ] `SKILL.md` 的 `description` 仍能正確觸發（主題沒跑掉）。
- [ ] 舊版檔案未被刪除（只新增 / 標示）。
- [ ] CHANGELOG.md 已更新。

---

## 7. 唯一準則

所有版本、相容性、授權細節，最終以 **Broadcom TechDocs / Release Notes / Interop Matrix**
為準。本 repo 是「整理與快速查閱」用途，不取代官方文件。
