package terraform.policies.mandatory_tags_test

import rego.v1

import data.terraform.policies.mandatory_tags

plan_with(tags) := {"plan": {"resource_changes": [
	{"address": "alicloud_vpc.main", "mode": "managed", "type": "alicloud_vpc", "change": {"actions": ["create"], "after": {"vpc_name": "app", "tags": tags}}},
	{"address": "alicloud_security_group_rule.app", "mode": "managed", "type": "alicloud_security_group_rule", "change": {"actions": ["create"], "after": {"type": "ingress"}}},
	{"address": "alicloud_vswitch.old", "mode": "managed", "type": "alicloud_vswitch", "change": {"actions": ["delete"], "after": null}},
]}}

valid := {"ApplicationID": "APM0001234", "ApplicationOwner": "Jane.Doe@example.com", "BusinessOwner": "raj.k@example.com", "CostCenter": "CC10001", "WBSCode": "P-100234.01"}

test_valid_tags_pass if {
	count(mandatory_tags.deny) == 0 with input as plan_with(valid)
}

test_null_tags_fail if {
	count(mandatory_tags.deny) == 5 with input as plan_with(null)
}

test_missing_tag_fails if {
	mandatory_tags.deny == {"alicloud_vpc.main: missing tag 'WBSCode'"} with input as plan_with(object.remove(valid, ["WBSCode"]))
}

test_relational_mismatch_fails if {
	d := mandatory_tags.deny with input as plan_with(object.union(valid, {"ApplicationID": "APM0005678", "CostCenter": "CC20002"}))
	d == {
		"alicloud_vpc.main: ApplicationOwner does not match ServiceNow (expected li.wei@example.com)",
		"alicloud_vpc.main: BusinessOwner does not match ServiceNow (expected ana.s@example.com)",
		"alicloud_vpc.main: WBSCode 'P-100234.01' belongs to cost center CC10001",
	}
}

test_unknown_cost_center_fails if {
	"alicloud_vpc.main: CostCenter 'CC99999' not found/active in SAP" in mandatory_tags.deny with input as plan_with(object.union(valid, {"CostCenter": "CC99999"}))
}

test_unknown_tags_fail if {
	unknown := {"plan": {"resource_changes": [{"address": "alicloud_vpc.main", "mode": "managed", "type": "alicloud_vpc", "change": {"actions": ["create"], "after": {"vpc_name": "app"}, "after_unknown": {"tags": true}}}]}}
	mandatory_tags.deny == {"alicloud_vpc.main: tags are unknown until apply - tag values must be known at plan time"} with input as unknown
}

test_stale_snapshot_fails if {
	d := mandatory_tags.deny with input as plan_with(valid) with data.terraform.tag_reference.generated_at as "2026-01-01T00:00:00Z"
	count(d) == 1
}
