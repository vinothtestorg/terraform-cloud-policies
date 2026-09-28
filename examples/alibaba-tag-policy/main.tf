terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.243.0"
    }
  }
}

variable "tag_reference_path" {
  description = "Daily snapshot produced by the Tag Reference pipeline."
  type        = string
  default     = "../tag-reference/tag-reference.sample.json"
}

variable "target_folder_id" {
  description = "Resource Directory folder the policy is attached to (test on a single member first)."
  type        = string
}

locals {
  ref = jsondecode(file(var.tag_reference_path))

  # Policy keys must be lowercase; tag_key carries the case-sensitive tag name.
  # Allow-lists (can intercept) for low-cardinality keys; regex (matched_tags: detect and
  # remediate only, no interception) for high-cardinality keys such as WBS codes.
  tag_policy = {
    tags = {
      costcenter = {
        tag_key      = { "@@assign" = "CostCenter" }
        tag_value    = { "@@assign" = sort(keys(local.ref.cost_centers)) }
        enforced_for = { "@@assign" = ["ecs:instance", "rds:instance"] }
      }
      applicationid = {
        tag_key      = { "@@assign" = "ApplicationID" }
        tag_value    = { "@@assign" = sort(keys(local.ref.applications)) }
        enforced_for = { "@@assign" = ["ecs:instance", "rds:instance"] }
      }
    }
    matched_tags = {
      wbscode = {
        tag_key   = { "@@assign" = "WBSCode" }
        tag_value = { "@@assign" = "^[A-Z]-[0-9]{6}(\\.[0-9]{2})*$" }
      }
    }
  }
}

resource "alicloud_tag_policy" "mandatory" {
  policy_name    = "mandatory_cmdb_finance_tags"
  policy_desc    = "Generated from ServiceNow/SAP snapshot ${local.ref.generated_at}"
  user_type      = "RD"
  policy_content = jsonencode(local.tag_policy)
}

resource "alicloud_tag_policy_attachment" "folder" {
  policy_id   = alicloud_tag_policy.mandatory.id
  target_id   = var.target_folder_id
  target_type = "FOLDER"
}

# Detective control: presence of all mandatory tags (managed rule supports up to 6 tags).
resource "alicloud_config_rule" "required_tags" {
  rule_name                 = "required-cmdb-finance-tags"
  source_owner              = "ALIYUN"
  source_identifier         = "required-tags"
  risk_level                = 1
  config_rule_trigger_types = "ConfigurationItemChangeNotification"
  resource_types_scope      = ["ACS::ECS::Instance", "ACS::RDS::DBInstance", "ACS::OSS::Bucket", "ACS::VPC::VPC"]
  input_parameters = {
    tag1Key = "ApplicationID"
    tag2Key = "ApplicationOwner"
    tag3Key = "BusinessOwner"
    tag4Key = "CostCenter"
    tag5Key = "WBSCode"
  }
}
