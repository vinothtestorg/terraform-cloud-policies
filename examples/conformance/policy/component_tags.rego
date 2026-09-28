package main

import rego.v1

# Generated from `terraform providers schema -json` (aliyun/alicloud): types with a map `tags` attribute.
taggable := {t | some t in data.alicloud.taggable}

# Allowed: tags = var.tags, or merge(<extras>, var.tags) with var.tags last so mandatory keys win.
valid_tags_expr(expr) if expr == "${var.tags}"

valid_tags_expr(expr) if regex.match(`^\$\{merge\(.*,\s*var\.tags\)\}$`, expr)

deny contains msg if {
	some rtype, resources in input.resource
	rtype in taggable
	some name, blocks in resources
	some block in blocks
	not valid_tags_expr(object.get(block, "tags", ""))
	msg := sprintf("%s.%s: tags must be var.tags (the validated map from component.tags), or merge(<extras>, var.tags)", [rtype, name])
}
