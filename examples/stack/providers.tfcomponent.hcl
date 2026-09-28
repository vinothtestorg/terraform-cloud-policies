required_providers {
  alicloud = {
    source  = "aliyun/alicloud"
    version = "~> 1.293"
  }
  http = {
    source  = "hashicorp/http"
    version = "~> 3.5"
  }
}

provider "alicloud" "this" {
  config {
    region = var.region
    assume_role_with_oidc {
      oidc_provider_arn = var.oidc_provider_arn
      role_arn          = var.role_arn
      oidc_token        = var.identity_token
      role_session_name = "hcp-terraform-stacks"
    }
  }
}

provider "http" "this" {}
