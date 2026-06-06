#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
VCF SDDC Manager 純 REST 盤點 (唯讀)。

用途
  在沒有 PowerCLI 的環境 / CI 中，透過 SDDC Manager Public API 盤點
  domains / clusters / hosts / bundles / upgradables，輸出 JSON 盤點清單。
  純唯讀，不改動環境。

安全規則 (對應 lib 框架精神)
  - 不寫死密碼/IP。SDDC Manager FQDN 由 --sddc 帶入；
    帳密由環境變數 VCF_USER / VCF_PASS 提供 (建議由 SecretManagement/Vault 注入)。
  - 先測試環境再正式；本腳本為唯讀，不含任何變更動作。

API 路徑
  以官方 SDDC Manager Public API 文件為準：
  https://developer.broadcom.com/  (VMware Cloud Foundation API Reference)
  常用穩定路徑：
    POST /v1/tokens            取得 accessToken
    GET  /v1/domains
    GET  /v1/clusters
    GET  /v1/hosts
    GET  /v1/bundles
    GET  /v1/upgradables
    GET  /v1/sddc-managers

範例
  export VCF_USER='administrator@vsphere.local'
  export VCF_PASS='***'
  python3 get_vcf_inventory.py --sddc sddc-uat.lab.local --out inventory-uat.json
"""
import argparse
import json
import os
import sys
import urllib3

try:
    import requests
except ImportError:
    sys.exit("需要 requests 套件：pip install requests")

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def get_token(base, user, pwd, verify):
    r = requests.post(
        f"{base}/v1/tokens",
        json={"username": user, "password": pwd},
        verify=verify, timeout=60,
    )
    r.raise_for_status()
    return r.json()["accessToken"]


def get_elements(base, path, headers, verify):
    """GET 一個 collection endpoint，回傳 elements 陣列 (容錯)。"""
    try:
        r = requests.get(f"{base}{path}", headers=headers, verify=verify, timeout=120)
        r.raise_for_status()
        data = r.json()
        return data.get("elements", data) if isinstance(data, dict) else data
    except Exception as exc:  # noqa: BLE001
        return {"_error": str(exc), "_path": path}


def main():
    ap = argparse.ArgumentParser(description="VCF SDDC Manager 唯讀盤點")
    ap.add_argument("--sddc", required=True, help="SDDC Manager FQDN，例 sddc-uat.lab.local")
    ap.add_argument("--out", default="vcf-inventory.json", help="輸出 JSON 檔名")
    ap.add_argument("--insecure", action="store_true", help="略過 TLS 驗證 (lab 用)")
    args = ap.parse_args()

    user = os.environ.get("VCF_USER")
    pwd = os.environ.get("VCF_PASS")
    if not user or not pwd:
        sys.exit("請以環境變數 VCF_USER / VCF_PASS 提供憑證 (勿寫死於腳本)。")

    base = f"https://{args.sddc}"
    verify = not args.insecure

    try:
        token = get_token(base, user, pwd, verify)
    except Exception as exc:  # noqa: BLE001
        sys.exit(f"取得 token 失敗：{exc}")

    headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}

    inventory = {
        "sddcManager": args.sddc,
        "sddcManagers": get_elements(base, "/v1/sddc-managers", headers, verify),
        "domains": get_elements(base, "/v1/domains", headers, verify),
        "clusters": get_elements(base, "/v1/clusters", headers, verify),
        "hosts": get_elements(base, "/v1/hosts", headers, verify),
        "bundles": get_elements(base, "/v1/bundles", headers, verify),
        "upgradables": get_elements(base, "/v1/upgradables", headers, verify),
    }

    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(inventory, fh, ensure_ascii=False, indent=2)

    # 簡短摘要
    def count(x):
        return len(x) if isinstance(x, list) else 0
    print("==== VCF 盤點摘要 (唯讀) ====")
    print(f"  Domains     : {count(inventory['domains'])}")
    print(f"  Clusters    : {count(inventory['clusters'])}")
    print(f"  Hosts       : {count(inventory['hosts'])}")
    print(f"  Bundles     : {count(inventory['bundles'])}")
    print(f"  Upgradables : {count(inventory['upgradables'])}")
    print(f"已輸出：{args.out}")


if __name__ == "__main__":
    main()
