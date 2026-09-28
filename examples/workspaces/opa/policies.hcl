policy "alicloud-mandatory-tags" {
  query             = "data.terraform.policies.mandatory_tags.deny"
  enforcement_level = "mandatory"
  description       = "AliCloud resources must carry ServiceNow/SAP-valid mandatory tags"
}
