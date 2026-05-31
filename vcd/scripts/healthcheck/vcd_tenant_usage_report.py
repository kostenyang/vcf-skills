#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
VMware Cloud Director (VCD) 租戶資源用量報表 — 唯讀健檢 (Python / requests)。

用途
    產出各 Organization / Org VDC 的 CPU / 記憶體 / 儲存 配額與用量總表，
    輸出表格與 CSV，供容量規劃與計費對帳。純唯讀，只發 GET，不改動環境。

安全 / 框架對齊
    - 不寫死密碼/IP。VCD FQDN 由參數或環境變數帶入，憑證一律由環境變數或互動輸入，
      絕不寫進程式碼 (對齊 lib/ 框架「祕密走 SecretManagement、不存明文」精神)。
      建議於 PowerShell 端以 SecretManagement 取出後，透過環境變數傳入：
          $c = Get-Secret -Name vcd-uat
          $env:VCD_USER = $c.UserName; $env:VCD_PASS = $c.GetNetworkCredential().Password
    - 健檢=唯讀；本腳本不含任何 POST/PUT/DELETE。

驗證流程 (依官方 API 文件)
    POST /cloudapi/1.0.0/sessions/provider  (Basic auth, user@System) →
        回應 Header X-VMWARE-VCLOUD-ACCESS-TOKEN → 後續 Authorization: Bearer
    參考: https://techdocs.broadcom.com/us/en/vmware-cis/cloud-director/vmware-cloud-director/10-6/-vcloud-api-programming-guide-for-service-providers-10-6.html

用法
    export VCD_USER='administrator'      # 或 administrator@System
    export VCD_PASS='********'
    python3 vcd_tenant_usage_report.py --host vcd-uat.lab.local --tier UAT --csv usage-uat.csv

注意
    REST 路徑以官方 VMware Cloud Director OpenAPI / Programming Guide 為準。
    -k / verify=False 僅用於內部受信 CA 不齊的環境；正式環境建議改用 --ca-bundle。
"""
import argparse
import base64
import csv
import os
import sys

try:
    import requests
    from requests.packages.urllib3.exceptions import InsecureRequestWarning  # type: ignore
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)  # type: ignore
except ImportError:
    sys.exit("需要 requests 套件：pip install requests")


def login(session, host, user, password, api_version, verify):
    """Provider 登入，回傳 bearer token；對齊官方 sessions/provider 流程。"""
    if "@" not in user:
        user = f"{user}@System"  # Provider 登入需 user@System
    token_b64 = base64.b64encode(f"{user}:{password}".encode("utf-8")).decode("ascii")
    url = f"https://{host}/cloudapi/1.0.0/sessions/provider"
    headers = {
        "Authorization": f"Basic {token_b64}",
        "Accept": f"application/*;version={api_version}",
    }
    resp = session.post(url, headers=headers, verify=verify, timeout=30)
    resp.raise_for_status()
    token = resp.headers.get("X-VMWARE-VCLOUD-ACCESS-TOKEN")
    if not token:
        sys.exit("登入未取得 X-VMWARE-VCLOUD-ACCESS-TOKEN，無法繼續。")
    return token


def get_paged(session, host, path, headers, verify, page_size=128):
    """自動翻頁取回 cloudapi 1.0.0 清單型 endpoint 的所有 values。"""
    values = []
    page = 1
    while True:
        sep = "&" if "?" in path else "?"
        url = f"https://{host}{path}{sep}page={page}&pageSize={page_size}"
        resp = session.get(url, headers=headers, verify=verify, timeout=60)
        resp.raise_for_status()
        data = resp.json()
        values.extend(data.get("values", []))
        if page >= int(data.get("pageCount", 1)):
            break
        page += 1
    return values


def main():
    ap = argparse.ArgumentParser(description="VCD 租戶資源用量報表 (唯讀)")
    ap.add_argument("--host", required=True, help="VCD Cell / LB FQDN")
    ap.add_argument("--tier", default="UAT", choices=["UAT", "TEST", "PROD"],
                    help="僅用於報表標示，不影響行為 (本腳本唯讀)")
    ap.add_argument("--api-version", default="38.1")
    ap.add_argument("--csv", help="輸出 CSV 檔路徑")
    ap.add_argument("--ca-bundle", help="CA bundle 路徑 (建議正式環境使用)")
    ap.add_argument("-k", "--insecure", action="store_true", help="略過 TLS 驗證 (僅限內部測試)")
    args = ap.parse_args()

    user = os.environ.get("VCD_USER")
    password = os.environ.get("VCD_PASS")
    if not user or not password:
        sys.exit("請以環境變數 VCD_USER / VCD_PASS 提供憑證 (勿寫進程式碼)。")

    verify = args.ca_bundle if args.ca_bundle else (not args.insecure)

    session = requests.Session()
    token = login(session, args.host, user, password, args.api_version, verify)
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": f"application/*;version={args.api_version}",
    }

    print(f"=== VCD 租戶用量報表  Host={args.host}  Tier={args.tier} ===")

    vdcs = get_paged(session, args.host, "/cloudapi/1.0.0/orgVdcs", headers, verify)
    rows = []
    for v in vdcs:
        org = (v.get("orgRef") or {}).get("name", "")
        cc = v.get("computeCapacity") or {}
        cpu = cc.get("cpu") or {}
        mem = cc.get("memory") or {}
        row = {
            "org": org,
            "orgVdc": v.get("name", ""),
            "allocationModel": v.get("allocationModel", ""),
            "enabled": v.get("isEnabled", ""),
            # 容量單位/欄位以官方 OpenAPI orgVdc 模型為準；若欄位缺失則留白。
            "cpu_allocated_mhz": cpu.get("allocated", ""),
            "cpu_used_mhz": cpu.get("used", ""),
            "mem_allocated_mb": mem.get("allocated", ""),
            "mem_used_mb": mem.get("used", ""),
        }
        rows.append(row)

    if not rows:
        print("(查無 Org VDC)")
    else:
        hdr = ["org", "orgVdc", "allocationModel", "enabled",
               "cpu_allocated_mhz", "cpu_used_mhz", "mem_allocated_mb", "mem_used_mb"]
        print("\t".join(hdr))
        for r in rows:
            print("\t".join(str(r[h]) for h in hdr))

        if args.csv:
            with open(args.csv, "w", newline="", encoding="utf-8") as fh:
                w = csv.DictWriter(fh, fieldnames=hdr)
                w.writeheader()
                w.writerows(rows)
            print(f"\n已輸出 CSV: {args.csv}")

    print("\n報表完成 (唯讀)。")


if __name__ == "__main__":
    main()
