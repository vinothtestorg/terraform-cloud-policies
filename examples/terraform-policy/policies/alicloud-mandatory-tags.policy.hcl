# Validates mandatory ServiceNow/SAP tags on AliCloud resources in Stacks and workspaces.
# Terraform policy is BETA - pilot only (HashiCorp: do not use beta features in production).
policy {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.293.0, < 2.0.0"
    }
  }
  terraform_config {
    required_version = ">= 1.16.0"
  }
}

input "tag_reference_url" {
  type        = string
  description = "Tag Validation Service endpoint returning the current reference data (live cache, snapshot fallback)."
}

input "tag_reference_token" {
  type      = string
  sensitive = true
}

input "mandatory_tags" {
  type    = list(string)
  default = ["ApplicationID", "ApplicationOwner", "BusinessOwner", "CostCenter", "WBSCode"]
}

locals {
  # One request per policy evaluation; the service answers from its SNOW/SAP cache.
  # tfpolicy 0.3.0: the second argument is the header map itself (not { headers = {...} }).
  # An unreachable service becomes statusCode 0, so the policy fails closed with a clear message.
  ref_response = core::try(core::gethttprequest(input.tag_reference_url, {
    "Authorization" = "Bearer ${input.tag_reference_token}"
  }), { statusCode = 0, status = "unreachable", body = "" })
  ref = core::try(core::jsondecode(local.ref_response.body), { applications = {}, cost_centers = {}, wbs_elements = {} })
}

# Most alicloud_* types have no tags attribute, and a few use a plain string (for example
# alicloud_mse_nacos_config), so every tag read goes through core::try and the filter
# keeps only resources whose tags attribute is a map or null.
resource_policy "alicloud_*" "mandatory_tags" {
  operations        = ["create", "update"]
  enforcement_level = "mandatory"
  filter            = core::can(attrs.tags) && !core::can(core::lower(attrs.tags))

  locals {
    tags    = core::try(core::merge({}, attrs.tags), {})
    missing = [for k in input.mandatory_tags : k if core::try(local.tags[k], "") == ""]
    app_id  = core::try(local.tags.ApplicationID, "")
    cc      = core::try(local.tags.CostCenter, "")
    wbs_id  = core::try(local.tags.WBSCode, "")
    app     = core::try(local.ref.applications[local.app_id], null)
    wbs     = core::try(local.ref.wbs_elements[local.wbs_id], null)
  }

  enforce {
    condition     = local.ref_response.statusCode == 200
    error_message = "Tag reference service unavailable (HTTP ${local.ref_response.statusCode}) - failing closed."
  }
  enforce {
    condition     = core::length(local.missing) == 0
    error_message = "Missing mandatory tags: ${core::join(", ", local.missing)}"
  }
  enforce {
    condition     = local.app_id == "" || local.app != null
    error_message = "ApplicationID '${local.app_id}' not found/active in ServiceNow."
  }
  enforce {
    condition     = local.app == null || core::lower(core::try(local.tags.ApplicationOwner, "")) == core::try(local.app.app_owner, "")
    error_message = "ApplicationOwner does not match ServiceNow (expected ${core::try(local.app.app_owner, "n/a")})."
  }
  enforce {
    condition     = local.app == null || core::lower(core::try(local.tags.BusinessOwner, "")) == core::try(local.app.business_owner, "")
    error_message = "BusinessOwner does not match ServiceNow (expected ${core::try(local.app.business_owner, "n/a")})."
  }
  enforce {
    condition     = local.cc == "" || core::contains(core::keys(local.ref.cost_centers), local.cc)
    error_message = "CostCenter '${local.cc}' not found/active in SAP."
  }
  enforce {
    condition     = local.wbs_id == "" || local.wbs != null
    error_message = "WBSCode '${local.wbs_id}' not found/released in SAP."
  }
  enforce {
    condition     = local.wbs == null || core::try(local.wbs.cost_center, "") == local.cc
    error_message = "WBSCode '${local.wbs_id}' belongs to cost center ${core::try(local.wbs.cost_center, "n/a")}."
  }
}
