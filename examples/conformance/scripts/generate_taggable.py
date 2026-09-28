"""Regenerate data/alicloud_taggable.json from the AliCloud provider schema.

Usage (from any directory initialised with the aliyun/alicloud provider):
  terraform providers schema -json | python3 generate_taggable.py > ../data/alicloud_taggable.json
"""
import json
import sys

schema = json.load(sys.stdin)
resources = schema["provider_schemas"]["registry.terraform.io/aliyun/alicloud"]["resource_schemas"]
taggable = sorted(
    rtype for rtype, spec in resources.items()
    if spec["block"].get("attributes", {}).get("tags", {}).get("type") == ["map", "string"]
)
json.dump({"alicloud": {"taggable": taggable}}, sys.stdout, indent=1)
print()
print(f"{len(taggable)} of {len(resources)} resource types have a map 'tags' attribute", file=sys.stderr)
