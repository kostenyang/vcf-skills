#!/usr/bin/env python3
"""HCX 健檢 (唯讀, 純 REST 版)。

適用無 PowerCLI 的跳板機 / CI。查詢 site pairing、Service Mesh、Network Extension
與進行中遷移。**唯讀，不改動環境。**

設計原則 (對齊 lib 框架硬性規則)：
  - 不寫死密碼/IP：HcxManager 由 --environment 對應的 environments.psd1 取得，
    或以環境變數帶入；憑證走 SecretManagement / 環境變數，不接受明文參數。
  - 先測試後正式：本腳本唯讀，任何環境可跑；變更類操作請走 PowerShell change/ 腳本。

HCX REST 基底：https://<HcxManager>/hybridity/api
端點路徑以官方 API 文件為準：
  https://techdocs.broadcom.com/us/en/vmware-cis/hcx/vmware-hcx/4-11.html

用法:
  export HCX_MANAGER=hcx-uat.lab.local
  export HCX_USER='administrator@vsphere.local'
  export HCX_PASS_SECRET=...   # 建議由 secret store 注入，勿明文落地
  python3 hcx_health.py --environment uat
"""
import argparse
import os
import sys
import urllib3

try:
    import requests
except ImportError:
    sys.exit("需要 requests 套件：pip install requests")

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def get_config():
    """由環境變數取得連線資訊；不接受明文密碼當命令列參數。"""
    mgr = os.environ.get("HCX_MANAGER")
    user = os.environ.get("HCX_USER")
    pwd = os.environ.get("HCX_PASS")  # 建議由 secret store 於執行期注入
    if not (mgr and user and pwd):
        sys.exit("請以環境變數提供 HCX_MANAGER / HCX_USER / HCX_PASS (勿寫死於腳本)。")
    return mgr, user, pwd


class HcxClient:
    def __init__(self, manager, user, pwd):
        self.base = f"https://{manager}/hybridity/api"
        self.s = requests.Session()
        self.s.verify = False
        self._auth(user, pwd)

    def _auth(self, user, pwd):
        # POST /sessions -> x-hm-authorization header
        r = self.s.post(
            f"{self.base}/sessions",
            json={"username": user, "password": pwd},
            timeout=30,
        )
        r.raise_for_status()
        token = r.headers.get("x-hm-authorization")
        if not token:
            sys.exit("登入失敗：未取得 x-hm-authorization token。")
        self.s.headers.update({"x-hm-authorization": token,
                               "Content-Type": "application/json"})

    def get(self, path):
        r = self.s.get(f"{self.base}{path}", timeout=60)
        r.raise_for_status()
        return r.json()

    def post(self, path, body):
        r = self.s.post(f"{self.base}{path}", json=body, timeout=60)
        r.raise_for_status()
        return r.json()


def main():
    ap = argparse.ArgumentParser(description="HCX 健檢 (唯讀)")
    ap.add_argument("--environment", required=True, choices=["uat", "test", "prod"])
    ap.parse_args()

    mgr, user, pwd = get_config()
    print(f"=== HCX 健檢 (唯讀) @ {mgr} ===")
    c = HcxClient(mgr, user, pwd)

    try:
        print("\n[Site Pairing]")
        cfg = c.get("/cloudConfigs")
        for it in (cfg.get("data", {}).get("items") or []):
            print(f"  {it.get('name'):30}  url={it.get('url')}")

        print("\n[Service Mesh]")
        sm = c.post("/interconnect/serviceMesh", {})
        for m in (sm.get("items") or []):
            print(f"  ServiceMesh: {m.get('name')}")

        print("\n[Network Extension]")
        l2 = c.get("/l2Extensions")
        for e in (l2.get("items") or []):
            print(f"  {e.get('networkName')}")

        print("\n[進行中遷移]")
        mig = c.post("/migrations?action=query", {"filter": {}, "options": {}})
        active = [m for m in (mig.get("items") or [])
                  if m.get("state") in ("MIGRATING", "RUNNING", "TRANSFER")]
        if not active:
            print("  (無進行中遷移)")
        for m in active:
            info = m.get("migrationInfo", {})
            print(f"  VM={info.get('entityName')} type={m.get('migrationType')} state={m.get('state')}")

        print("\n健檢完成 (唯讀)。")
    except requests.HTTPError as exc:
        sys.exit(f"HCX API 錯誤：{exc} :: {getattr(exc.response, 'text', '')}")


if __name__ == "__main__":
    main()
