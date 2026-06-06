#!/usr/bin/env python3
"""VCF 5.2.1 跨網域唯讀盤點 (純 REST / requests)。

用途
----
以 SDDC Manager Public API (/v1) 盤點 domains / clusters / hosts 與目前版本，
適合排程或 CI 內的唯讀健檢。本腳本『唯讀』，不會改動環境。

安全原則 (對齊 lib 框架精神)
----------------------------
- 不寫死密碼/IP：SDDC Manager FQDN 由 --sddc 參數帶入；
  帳密由環境變數 VCF_USERNAME / VCF_PASSWORD 取得 (建議由密碼管理工具注入)。
- 唯讀：只發 GET 與取得 token 用的 POST /v1/tokens。
- TLS：預設驗證；實驗室自簽憑證可加 --insecure (僅限非正式環境)。

API 路徑以官方文件為準：
  https://developer.broadcom.com/xapis/vmware-cloud-foundation-api/latest/

用法
----
  export VCF_USERNAME='administrator@vsphere.local'
  export VCF_PASSWORD='********'
  python3 get_vcf_inventory.py --sddc sddc-mgr.uat.example.com --insecure
"""
import argparse
import os
import sys
import json

import requests
import urllib3


def get_token(base, user, pwd, verify):
    r = requests.post(
        f"{base}/v1/tokens",
        json={"username": user, "password": pwd},
        verify=verify,
        timeout=30,
    )
    r.raise_for_status()
    return r.json()["accessToken"]


def get(base, path, token, verify):
    r = requests.get(
        f"{base}{path}",
        headers={"Authorization": f"Bearer {token}"},
        verify=verify,
        timeout=60,
    )
    r.raise_for_status()
    return r.json()


def main():
    ap = argparse.ArgumentParser(description="VCF 5.2.1 唯讀盤點")
    ap.add_argument("--sddc", required=True, help="SDDC Manager FQDN")
    ap.add_argument("--insecure", action="store_true",
                    help="略過 TLS 驗證 (僅限非正式環境)")
    ap.add_argument("--json", action="store_true", help="以 JSON 輸出")
    args = ap.parse_args()

    user = os.environ.get("VCF_USERNAME")
    pwd = os.environ.get("VCF_PASSWORD")
    if not user or not pwd:
        print("錯誤：請設定環境變數 VCF_USERNAME 與 VCF_PASSWORD", file=sys.stderr)
        sys.exit(2)

    verify = not args.insecure
    if args.insecure:
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        print("[警告] 已停用 TLS 驗證，僅應用於非正式環境。", file=sys.stderr)

    base = f"https://{args.sddc}"
    token = get_token(base, user, pwd, verify)

    domains = get(base, "/v1/domains", token, verify).get("elements", [])
    clusters = get(base, "/v1/clusters", token, verify).get("elements", [])
    hosts = get(base, "/v1/hosts", token, verify).get("elements", [])

    inv = {
        "sddcManager": args.sddc,
        "domains": [
            {"name": d.get("name"), "type": d.get("type"), "status": d.get("status")}
            for d in domains
        ],
        "clusters": [
            {"name": c.get("name"), "status": c.get("status"),
             "datastore": c.get("primaryDatastoreType")}
            for c in clusters
        ],
        "hosts": [
            {"fqdn": h.get("fqdn"), "status": h.get("status"),
             "esxiVersion": h.get("esxiVersion")}
            for h in hosts
        ],
    }

    if args.json:
        print(json.dumps(inv, indent=2, ensure_ascii=False))
    else:
        print(f"SDDC Manager: {args.sddc}")
        print(f"Domains : {len(inv['domains'])}")
        for d in inv["domains"]:
            print(f"  - {d['name']:<24} {d['type']:<12} {d['status']}")
        print(f"Clusters: {len(inv['clusters'])}")
        print(f"Hosts   : {len(inv['hosts'])}")
        bad = [h for h in inv["hosts"]
               if h["status"] not in ("ASSIGNED", "ACTIVE", None)]
        if bad:
            print(f"[警告] {len(bad)} 台 host 狀態異常")


if __name__ == "__main__":
    try:
        main()
    except requests.HTTPError as e:
        print(f"HTTP 錯誤：{e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:  # noqa: BLE001
        print(f"盤點失敗：{e}", file=sys.stderr)
        sys.exit(1)
