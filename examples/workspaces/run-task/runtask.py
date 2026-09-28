"""Minimal HCP Terraform run task: validates AliCloud resource tags against ServiceNow/SAP."""
import hashlib, hmac, json, os, threading, urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HMAC_KEY = os.environ["RUN_TASK_HMAC_KEY"].encode()
MANDATORY = ["ApplicationID", "ApplicationOwner", "BusinessOwner", "CostCenter", "WBSCode"]


def tfc(method, url, token, body=None):
    req = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body else None,
                                 headers={"Authorization": f"Bearer {token}",
                                          "Content-Type": "application/vnd.api+json"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp) if method == "GET" else None


def in_scope(plan):
    """AliCloud managed resources being created/updated that support a `tags` argument."""
    for rc in plan.get("resource_changes", []):
        after = rc["change"].get("after") or {}
        unknown = (rc["change"].get("after_unknown") or {}).get("tags") is True  # unknown => treated as missing
        if (rc["mode"] == "managed" and rc["type"].startswith("alicloud_")
                and {"create", "update"} & set(rc["change"]["actions"]) and ("tags" in after or unknown)):
            yield rc["address"], after.get("tags") or {}


def validate(tags, reference):
    """reference = live SNOW/SAP lookup client (cached), falling back to the daily snapshot."""
    errors = [f"missing tag `{k}`" for k in MANDATORY if not tags.get(k)]
    return errors or reference.check(tags)


def evaluate(payload, reference):
    plan = tfc("GET", payload["plan_json_api_url"], payload["access_token"])
    outcomes = []
    for address, tags in in_scope(plan):
        if errors := validate(tags, reference):
            outcomes.append({"type": "task-result-outcomes", "attributes": {
                "outcome-id": address,
                "description": f"{address}: {len(errors)} tag violation(s)",
                "body": "\n".join(f"- {e}" for e in errors),
                "tags": {"Status": [{"label": "Failed", "level": "error"}]}}})
    tfc("PATCH", payload["task_result_callback_url"], payload["access_token"], {"data": {
        "type": "task-results",
        "attributes": {"status": "failed" if outcomes else "passed",
                       "message": f"{len(outcomes)} resource(s) with invalid ServiceNow/SAP tags"},
        "relationships": {"outcomes": {"data": outcomes}}}})


def make_handler(reference):
    class Handler(BaseHTTPRequestHandler):
        def do_POST(self):
            body = self.rfile.read(int(self.headers["Content-Length"]))
            expected = hmac.new(HMAC_KEY, body, hashlib.sha512).hexdigest()
            if not hmac.compare_digest(expected, self.headers.get("X-Tfc-Task-Signature", "")):
                self.send_response(401); self.end_headers(); return
            payload = json.loads(body)
            self.send_response(200); self.end_headers()   # ack fast; the verdict goes via callback
            if payload.get("access_token") != "test-token":  # "test-token" = registration ping
                threading.Thread(target=evaluate, args=(payload, reference), daemon=True).start()
    return Handler


if __name__ == "__main__":
    from reference import TagReference  # your SNOW/SAP client + snapshot fallback
    ThreadingHTTPServer(("0.0.0.0", 8080), make_handler(TagReference())).serve_forever()
