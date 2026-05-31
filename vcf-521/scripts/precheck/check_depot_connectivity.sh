#!/usr/bin/env bash
#
# check_depot_connectivity.sh
#
# 用途：升級前快速驗證 SDDC Manager 對 Depot 的連線與認證 (KB 390098)。
#       唯讀：取得 token + GET depot 設定，不改動環境。
#
# 安全原則 (對齊 lib 框架精神)：
#   - 不寫死密碼/IP：SDDC Manager FQDN 由 --sddc 帶入；
#     帳密由環境變數 VCF_USERNAME / VCF_PASSWORD 提供。
#   - 先測試環境；正式環境連線僅做唯讀查詢。
#   - TLS 預設驗證；自簽實驗室可加 --insecure (僅限非正式)。
#
# API 路徑以官方文件為準：
#   https://developer.broadcom.com/xapis/vmware-cloud-foundation-api/latest/
#
# 用法：
#   export VCF_USERNAME='administrator@vsphere.local'
#   export VCF_PASSWORD='********'
#   ./check_depot_connectivity.sh --sddc sddc-mgr.test.example.com [--insecure]
#
set -euo pipefail

SDDC=""
INSECURE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sddc) SDDC="$2"; shift 2 ;;
    --insecure) INSECURE="-k"; shift ;;
    *) echo "未知參數：$1" >&2; exit 2 ;;
  esac
done

if [[ -z "$SDDC" ]]; then
  echo "錯誤：請以 --sddc <FQDN> 指定 SDDC Manager" >&2
  exit 2
fi
if [[ -z "${VCF_USERNAME:-}" || -z "${VCF_PASSWORD:-}" ]]; then
  echo "錯誤：請設定環境變數 VCF_USERNAME 與 VCF_PASSWORD" >&2
  exit 2
fi
if [[ -n "$INSECURE" ]]; then
  echo "[警告] 已停用 TLS 驗證，僅應用於非正式環境。" >&2
fi

BASE="https://${SDDC}"

echo "== 取得 SDDC Manager token =="
TOKEN=$(curl -sS $INSECURE -X POST "${BASE}/v1/tokens" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"${VCF_USERNAME}\",\"password\":\"${VCF_PASSWORD}\"}" \
  | sed -n 's/.*"accessToken"[ ]*:[ ]*"\([^"]*\)".*/\1/p')

if [[ -z "$TOKEN" ]]; then
  echo "[失敗] 無法取得 token，請檢查帳密與連線。" >&2
  exit 1
fi
echo "  [OK] 已取得 token"

echo "== 查詢 Depot 設定 (KB 390098) =="
curl -sS $INSECURE "${BASE}/v1/system/settings/depot" \
  -H "Authorization: Bearer ${TOKEN}" || true
echo

echo "== 查詢 bundle 下載狀態摘要 =="
curl -sS $INSECURE "${BASE}/v1/bundles" \
  -H "Authorization: Bearer ${TOKEN}" \
  | grep -o '"downloadStatus"[ ]*:[ ]*"[^"]*"' | sort | uniq -c || true

echo
echo "提醒：KB 390098 — Depot 驗證方式已變更，請確認已設定有效下載 token / Broadcom 帳號。"
echo "檢查完成 (唯讀)。"
