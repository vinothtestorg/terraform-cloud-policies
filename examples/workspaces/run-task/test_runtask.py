import hashlib, hmac, json, os, threading, time, urllib.request
os.environ["RUN_TASK_HMAC_KEY"] = "s3cret"
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import runtask

class Ref:
    def check(self, t):
        e = []
        if t["CostCenter"] not in {"CC10001"}: e.append(f"CostCenter {t['CostCenter']} not active in SAP")
        return e

PLAN = {"resource_changes": [
  {"address": "alicloud_vpc.ok", "mode": "managed", "type": "alicloud_vpc", "change": {"actions": ["create"], "after": {"tags": {"ApplicationID": "APM0001234", "ApplicationOwner": "a", "BusinessOwner": "b", "CostCenter": "CC10001", "WBSCode": "P-1"}}}},
  {"address": "alicloud_vswitch.bad", "mode": "managed", "type": "alicloud_vswitch", "change": {"actions": ["update"], "after": {"tags": {"ApplicationID": "APM0001234", "ApplicationOwner": "a", "BusinessOwner": "b", "CostCenter": "CC99999", "WBSCode": "P-1"}}}},
  {"address": "alicloud_oss_bucket.none", "mode": "managed", "type": "alicloud_oss_bucket", "change": {"actions": ["create"], "after": {"tags": None}}},
  {"address": "alicloud_slb.unknown", "mode": "managed", "type": "alicloud_slb", "change": {"actions": ["create"], "after": {}, "after_unknown": {"tags": True}}},
  {"address": "alicloud_security_group_rule.skip", "mode": "managed", "type": "alicloud_security_group_rule", "change": {"actions": ["create"], "after": {"type": "ingress"}}},
  {"address": "alicloud_vpc.gone", "mode": "managed", "type": "alicloud_vpc", "change": {"actions": ["delete"], "after": None}},
]}
captured = []
class FakeTFC(BaseHTTPRequestHandler):
    def do_GET(self):
        assert self.headers["Authorization"] == "Bearer tok"
        self.send_response(200); self.end_headers(); self.wfile.write(json.dumps(PLAN).encode())
    def do_PATCH(self):
        captured.append(json.loads(self.rfile.read(int(self.headers["Content-Length"]))))
        self.send_response(200); self.end_headers()
    def log_message(self, *a): pass
runtask.make_handler(Ref()).log_message = lambda *a: None
for srv in (ThreadingHTTPServer(("127.0.0.1", 18081), FakeTFC), ThreadingHTTPServer(("127.0.0.1", 18082), runtask.make_handler(Ref()))):
    threading.Thread(target=srv.serve_forever, daemon=True).start()

def post(payload, key=b"s3cret"):
    body = json.dumps(payload).encode()
    req = urllib.request.Request("http://127.0.0.1:18082/", data=body, method="POST",
        headers={"X-Tfc-Task-Signature": hmac.new(key, body, hashlib.sha512).hexdigest(), "Content-Length": str(len(body))})
    try: return urllib.request.urlopen(req).status
    except urllib.error.HTTPError as e: return e.code

assert post({"access_token": "test-token"}) == 200 and not captured          # registration ping
assert post({"access_token": "tok"}, key=b"wrong") == 401                     # bad signature
assert post({"access_token": "tok", "stage": "post_plan", "plan_json_api_url": "http://127.0.0.1:18081/plan",
             "task_result_callback_url": "http://127.0.0.1:18081/cb"}) == 200
for _ in range(50):
    if captured: break
    time.sleep(0.1)
d = captured[0]["data"]
outs = {o["attributes"]["outcome-id"]: o["attributes"]["body"] for o in d["relationships"]["outcomes"]["data"]}
print(d["attributes"]); print(json.dumps(outs, indent=1))
assert d["attributes"]["status"] == "failed" and set(outs) == {"alicloud_vswitch.bad", "alicloud_oss_bucket.none", "alicloud_slb.unknown"}
print("ALL OK")
