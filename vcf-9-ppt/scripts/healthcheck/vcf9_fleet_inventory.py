#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
vcf9_fleet_inventory.py — VCF 9 唯讀 Fleet/Domain/Cluster/Host 盤點 (純 REST)

用途
    在沒有 PowerCLI 的環境 (例如 Linux 跳板機) 快速盤點 SDDC Manager 管理的
    Domain / Cluster / Host 清單與版本，輸出表格或 JSON。純唯讀 (ReadOnly)，
    不會改動環境。

安全分級
    ReadOnly — 可直接於 PROD 執行。

遵循硬性規則
    - 不寫死密碼/IP：SDDC Manager 由 --sddc 帶入；帳密由環境變數
      VCF_USER / VCF_PASS 取得 (建議改接 vault；此處示範以環境變數注入)。
    - 不杜撰 API：使用 VCF SDDC Manager v1 REST。路徑以官方 API 文件為準：
      https://developer.broadcom.com/xapis (VMware Cloud Foundation API Reference)

範例
    export VCF_USER='administrator@vsphere.local'
    export VCF_PASS='********'
    python3 vcf9_fleet_inventory.py --sddc sddc.corp.local --json out.json
"""
import argparse
import json
import os
import sys

try:
    import requests
    from requests.packages.urllib3.exceptions import InsecureRequestWarning  # type: ignore
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
except ImportError:
    sys.exit("需要 requests 套件：pip install requests")


def get_token(base, user, password, verify):
    """POST /v1/tokens 取得 accessToken (路徑以官方 API 文件為準)。"""
    r = requests.post(
        f"{base}/v1/tokens",
        json={"username": user, "password": password},
        verify=verify, timeout=30,
    )
    r.raise_for_status()
    return r.json()["accessToken"]


def get_elements(base, path, headers, verify):
    r = requests.get(f"{base}{path}", headers=headers, verify=verify, timeout=60)
    r.raise_for_status()
    data = r.json()
    return data.get("elements", data if isinstance(data, list) else [data])


def main():
    ap = argparse.ArgumentParser(description="VCF 9 唯讀 Fleet 盤點 (REST)")
    ap.add_argument("--sddc", required=True, help="SDDC Manager FQDN，不含 https://")
    ap.add_argument("--json", dest="json_out", help="另存 JSON 結果路徑")
    ap.add_argument("--insecure", action="store_true",
                    help="略過 TLS 驗證 (僅限實驗室；正式環境請改提供 CA)")
    args = ap.parse_args()

    user = os.environ.get("VCF_USER")
    password = os.environ.get("VCF_PASS")
    if not user or not password:
        sys.exit("請以環境變數 VCF_USER / VCF_PASS 提供帳密，勿寫死於腳本。")

    verify = not args.insecure
    base = f"https://{args.sddc}"

    print(f"[健檢] 連線 SDDC Manager {args.sddc} (ReadOnly)")
    try:
        token = get_token(base, user, password, verify)
    except requests.RequestException as e:
        sys.exit(f"取得 token 失敗：{e}")

    headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}
    report = {"sddc": args.sddc, "domains": [], "clusters": [], "hosts": []}

    try:
        report["domains"] = get_elements(base, "/v1/domains", headers, verify)
        report["clusters"] = get_elements(base, "/v1/clusters", headers, verify)
        report["hosts"] = get_elements(base, "/v1/hosts", headers, verify)
    except requests.RequestException as e:
        sys.exit(f"盤點失敗：{e}")

    print("\n== Domains ==")
    for d in report["domains"]:
        print(f"  {d.get('name'):30} type={d.get('type'):12} status={d.get('status')}")

    print("\n== Clusters ==")
    for c in report["clusters"]:
        img = c.get("isImageBased", "未知(查API)")
        print(f"  {c.get('name'):30} status={c.get('status'):10} imageBased={img}")

    print("\n== Hosts ==")
    for h in report["hosts"]:
        print(f"  {h.get('fqdn'):40} status={h.get('status'):10} esx={h.get('esxiVersion')}")

    if args.json_out:
        with open(args.json_out, "w", encoding="utf-8") as f:
            json.dump(report, f, ensure_ascii=False, indent=2)
        print(f"\n已輸出 JSON：{args.json_out}")

    print("\n✓ 盤點完成 (ReadOnly)。")


if __name__ == "__main__":
    main()
