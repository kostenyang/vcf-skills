#!/usr/bin/env bash
# 把 vcf-whats-new skill 上傳到 kostenyang/BroadcomPPT
# 用法： 解壓 vcf-whats-new.zip 後，在含有 vcf-whats-new/ 的目錄執行此腳本
set -e
REPO="git@github.com:kostenyang/BroadcomPPT.git"   # 或改 https://github.com/kostenyang/BroadcomPPT.git
BRANCH="main"
TMP=$(mktemp -d)
echo ">> clone $REPO"
git clone --depth 1 -b "$BRANCH" "$REPO" "$TMP"
echo ">> copy skill"
mkdir -p "$TMP/vcf-whats-new"
cp -f vcf-whats-new/SKILL.md "$TMP/vcf-whats-new/"
cp -f vcf-whats-new/TECH_TUESDAY_Whats_New_with_vSphere_in_VCF_9_1.pptx "$TMP/vcf-whats-new/"
cd "$TMP"
git add vcf-whats-new/SKILL.md vcf-whats-new/TECH_TUESDAY_Whats_New_with_vSphere_in_VCF_9_1.pptx
git commit -m "Add vcf-whats-new skill (VCF 9 Tech Tuesday What's New template)"
git push origin "$BRANCH"
echo ">> done. pushed to $REPO ($BRANCH)"
