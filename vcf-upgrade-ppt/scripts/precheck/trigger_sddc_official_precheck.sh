#!/usr/bin/env bash
# =============================================================================
# trigger_sddc_official_precheck.sh
#
# 觸發 SDDC Manager 內建的官方 system precheck (健康檢查) 並輪詢結果。
# 此 precheck 為「唯讀健康檢查工作流程」(non-destructive)，不會改動設定。
#
# 安全規則 (對應 lib 框架精神)
#   - 不寫死密碼/IP：SDDC FQDN 由 --sddc 帶入；帳密由 VCF_USER / VCF_PASS 環境變數提供。
#   - 先測試環境再正式：--prod 會要求二次輸入完整環境名稱確認後才送出。
#
# API 路徑 (以官方 SDDC Manager Public API 文件為準)
#   POST /v1/tokens                          取得 token
#   POST /v1/system/prechecks                送出 precheck (回傳 task id)
#   GET  /v1/system/prechecks/tasks/{id}     輪詢 precheck 結果
#   參考：https://developer.broadcom.com/ (VCF API Reference)
#
# 相依：curl、jq
#
# 範例：
#   export VCF_USER='administrator@vsphere.local'; export VCF_PASS='***'
#   ./trigger_sddc_official_precheck.sh --sddc sddc-uat.lab.local --insecure
#   ./trigger_sddc_official_precheck.sh --sddc sddc.corp.local --prod prod --insecure
# =============================================================================
set -euo pipefail

SDDC=""
INSECURE=""
PROD_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sddc)     SDDC="$2"; shift 2 ;;
    --insecure) INSECURE="-k"; shift ;;
    --prod)     PROD_NAME="$2"; shift 2 ;;   # 正式環境：傳入完整環境名稱以啟動二次確認
    *) echo "未知參數：$1" >&2; exit 2 ;;
  esac
done

[[ -z "$SDDC" ]] && { echo "用法：$0 --sddc <fqdn> [--insecure] [--prod <env-name>]" >&2; exit 2; }
[[ -z "${VCF_USER:-}" || -z "${VCF_PASS:-}" ]] && { echo "請以環境變數 VCF_USER / VCF_PASS 提供憑證 (勿寫死)。" >&2; exit 2; }
command -v jq >/dev/null   || { echo "需要 jq。" >&2; exit 2; }
command -v curl >/dev/null || { echo "需要 curl。" >&2; exit 2; }

BASE="https://${SDDC}"

# PROD 二次確認 (precheck 雖唯讀，仍對 PROD 提示一致行為)
if [[ -n "$PROD_NAME" ]]; then
  echo "[PROD] 即將對正式環境 ${SDDC} 觸發官方 precheck (唯讀)。"
  read -r -p "請完整輸入環境名稱 '${PROD_NAME}' 以繼續：" ans
  [[ "$ans" != "$PROD_NAME" ]] && { echo "[PROD 阻擋] 環境名稱不符，已中止。" >&2; exit 1; }
fi

echo "[1/3] 取得 token ..."
TOKEN=$(curl ${INSECURE} -s -X POST "${BASE}/v1/tokens" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"${VCF_USER}\",\"password\":\"${VCF_PASS}\"}" | jq -r '.accessToken')
[[ -z "$TOKEN" || "$TOKEN" == "null" ]] && { echo "取得 token 失敗。" >&2; exit 1; }

echo "[2/3] 送出 system precheck (唯讀健康檢查) ..."
# resources 範圍可依官方文件調整；此處請求對整個 SDDC 做一般 precheck。
TASK_ID=$(curl ${INSECURE} -s -X POST "${BASE}/v1/system/prechecks" \
  -H "Authorization: Bearer ${TOKEN}" -H 'Content-Type: application/json' \
  -d '{"resources":[{"type":"SYSTEM"}]}' | jq -r '.id // .taskId // empty')

[[ -z "$TASK_ID" ]] && { echo "未取得 precheck task id；請對照官方 API 確認 payload/路徑。" >&2; exit 1; }
echo "  precheck task id = ${TASK_ID}"

echo "[3/3] 輪詢 precheck 結果 ..."
for i in $(seq 1 120); do
  RESP=$(curl ${INSECURE} -s -X GET "${BASE}/v1/system/prechecks/tasks/${TASK_ID}" \
    -H "Authorization: Bearer ${TOKEN}")
  STATUS=$(echo "$RESP" | jq -r '.status // .state // "UNKNOWN"')
  echo "  [#${i}] status=${STATUS}"
  case "$STATUS" in
    COMPLETED_WITH_SUCCESS|SUCCESSFUL|COMPLETED)
      echo "$RESP" | jq '.'
      echo "precheck 完成 (成功)。請於 SDDC Manager UI 詳閱各項結果。"
      exit 0 ;;
    COMPLETED_WITH_FAILURE|FAILED|ERROR)
      echo "$RESP" | jq '.'
      echo "precheck 完成但有失敗項；請依結果與官方 KB remediation。" >&2
      exit 1 ;;
  esac
  sleep 15
done

echo "輪詢逾時；請至 SDDC Manager UI 查看 precheck task ${TASK_ID}。" >&2
exit 1
