"""Local stand-in for the Tag Validation Service, used by the example tests.

GET  /v1/tag-reference   -> current reference data (Terraform policy example); needs "Bearer test-token"
POST /v1/tags/validate   -> {"valid": bool, "errors": [...]} for {"tags": {...}} (golden tags module)

Serves ../tag-reference/tag-reference.sample.json. Usage: python3 mock_tag_api.py [port]  (default 18080)
"""
import json
import pathlib
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

REF = json.loads((pathlib.Path(__file__).parent.parent / "tag-reference" / "tag-reference.sample.json").read_text())
MANDATORY = ["ApplicationID", "ApplicationOwner", "BusinessOwner", "CostCenter", "WBSCode"]


def validate(tags):
    errors = [f"missing tag {k}" for k in MANDATORY if not tags.get(k)]
    if errors:
        return errors
    app = REF["applications"].get(tags["ApplicationID"])
    if not app:
        errors.append(f"ApplicationID {tags['ApplicationID']} not active in ServiceNow")
    else:
        if tags["ApplicationOwner"].lower() != app["app_owner"]:
            errors.append(f"ApplicationOwner must be {app['app_owner']}")
        if tags["BusinessOwner"].lower() != app["business_owner"]:
            errors.append(f"BusinessOwner must be {app['business_owner']}")
    if tags["CostCenter"] not in REF["cost_centers"]:
        errors.append(f"CostCenter {tags['CostCenter']} not active in SAP")
    wbs = REF["wbs_elements"].get(tags["WBSCode"])
    if not wbs:
        errors.append(f"WBSCode {tags['WBSCode']} not released in SAP")
    elif wbs["cost_center"] != tags["CostCenter"]:
        errors.append(f"WBSCode {tags['WBSCode']} belongs to cost center {wbs['cost_center']}")
    return errors


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(body).encode())

    def do_GET(self):
        if self.path != "/v1/tag-reference":
            return self._send(404, {"error": "not found"})
        if self.headers.get("Authorization") != "Bearer test-token":
            return self._send(401, {"error": "unauthorized"})
        self._send(200, REF)

    def do_POST(self):
        if self.path != "/v1/tags/validate":
            return self._send(404, {"error": "not found"})
        tags = json.loads(self.rfile.read(int(self.headers["Content-Length"])))["tags"]
        errors = validate(tags)
        self._send(200, {"valid": not errors, "errors": errors})

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 18080
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
