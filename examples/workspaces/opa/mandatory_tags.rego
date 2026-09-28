package terraform.policies.mandatory_tags

import rego.v1

import data.terraform.tag_reference as ref

mandatory := ["ApplicationID", "ApplicationOwner", "BusinessOwner", "CostCenter", "WBSCode"]

max_snapshot_age_hours := 48

# AliCloud managed resources being created/updated that support a "tags" argument
in_scope contains rc if {
	some rc in input.plan.resource_changes
	rc.mode == "managed"
	startswith(rc.type, "alicloud_")
	some action in rc.change.actions
	action in {"create", "update"}
	taggable(rc)
}

taggable(rc) if "tags" in object.keys(rc.change.after)

# a wholly unknown tags map is absent from "after" and flagged in "after_unknown"
taggable(rc) if tags_unknown(rc)

tags_unknown(rc) if rc.change.after_unknown.tags == true

deny contains msg if {
	some rc in in_scope
	tags_unknown(rc)
	msg := sprintf("%s: tags are unknown until apply - tag values must be known at plan time", [rc.address])
}

tags_of(rc) := rc.change.after.tags if rc.change.after.tags != null

else := {}

deny contains msg if {
	some rc in in_scope
	not tags_unknown(rc)
	some k in mandatory
	object.get(tags_of(rc), k, "") == ""
	msg := sprintf("%s: missing tag '%s'", [rc.address, k])
}

deny contains msg if {
	some rc in in_scope
	id := tags_of(rc).ApplicationID
	not ref.applications[id]
	msg := sprintf("%s: ApplicationID '%s' not found/active in ServiceNow", [rc.address, id])
}

deny contains msg if {
	some rc in in_scope
	t := tags_of(rc)
	app := ref.applications[t.ApplicationID]
	some pair in [["ApplicationOwner", app.app_owner], ["BusinessOwner", app.business_owner]]
	lower(object.get(t, pair[0], "")) != pair[1]
	msg := sprintf("%s: %s does not match ServiceNow (expected %s)", [rc.address, pair[0], pair[1]])
}

deny contains msg if {
	some rc in in_scope
	cc := tags_of(rc).CostCenter
	not ref.cost_centers[cc]
	msg := sprintf("%s: CostCenter '%s' not found/active in SAP", [rc.address, cc])
}

deny contains msg if {
	some rc in in_scope
	wbs := tags_of(rc).WBSCode
	not ref.wbs_elements[wbs]
	msg := sprintf("%s: WBSCode '%s' not found/released in SAP", [rc.address, wbs])
}

deny contains msg if {
	some rc in in_scope
	t := tags_of(rc)
	owner_cc := ref.wbs_elements[t.WBSCode].cost_center
	owner_cc != object.get(t, "CostCenter", "")
	msg := sprintf("%s: WBSCode '%s' belongs to cost center %s", [rc.address, t.WBSCode, owner_cc])
}

deny contains msg if {
	age_ns := time.now_ns() - time.parse_rfc3339_ns(ref.generated_at)
	age_ns > (max_snapshot_age_hours * 3600) * 1000000000
	msg := sprintf("tag_reference snapshot (%s) is older than %dh - check the SNOW/SAP sync job", [ref.generated_at, max_snapshot_age_hours])
}
