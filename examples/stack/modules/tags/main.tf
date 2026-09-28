terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
  }
}

variable "tags" {
  description = "Mandatory + optional tags for every AliCloud resource in this stack."
  type = object({
    ApplicationID    = string
    ApplicationOwner = string
    BusinessOwner    = string
    CostCenter       = string
    WBSCode          = string
    extra            = optional(map(string), {})
  })

  validation {
    condition     = can(regex("^APM[0-9]{7}$", var.tags.ApplicationID))
    error_message = "ApplicationID must be a ServiceNow business application number (APMnnnnnnn)."
  }
}

variable "validation_api_url" {
  description = "Internal tag lookup API (reachable from the self-hosted HCP Terraform agents)."
  type        = string
}

locals {
  mandatory = { for k, v in var.tags : k => v if k != "extra" }
}

# Evaluated during plan on the agent that runs this workspace
data "http" "tag_validation" {
  url             = "${var.validation_api_url}/v1/tags/validate"
  method          = "POST"
  request_headers = { "Content-Type" = "application/json" }
  request_body    = jsonencode({ tags = local.mandatory })

  retry {
    attempts     = 2
    min_delay_ms = 500
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200 && try(jsondecode(self.response_body).valid, false)
      error_message = "Tag validation against ServiceNow/SAP failed: ${try(join("; ", jsondecode(self.response_body).errors), "HTTP ${self.status_code}")}"
    }
  }
}

output "tags" {
  description = "Validated tag map - pass to every resource's tags argument."
  value       = merge(var.tags.extra, local.mandatory)
  depends_on  = [data.http.tag_validation]
}
