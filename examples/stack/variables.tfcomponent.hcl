variable "region" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "identity_token" {
  type      = string
  ephemeral = true
}

variable "tag_validation_api_url" {
  description = "Tag Validation Service, reachable from the Stack's self-hosted agents."
  type        = string
}

variable "tags" {
  description = "Mandatory ServiceNow/SAP tags for this deployment (validated by component.tags)."
  type = object({
    ApplicationID    = string
    ApplicationOwner = string
    BusinessOwner    = string
    CostCenter       = string
    WBSCode          = string
    extra            = optional(map(string), {})
  })
}
