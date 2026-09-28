identity_token "alicloud" {
  audience = ["alicloud.workload.identity"]
}

deployment "production" {
  inputs = {
    region                 = "ap-southeast-1"
    role_arn               = "acs:ram::123456789012:role/hcp-terraform-stacks"
    oidc_provider_arn      = "acs:ram::123456789012:oidc-provider/hcp-terraform"
    identity_token         = identity_token.alicloud.jwt
    tag_validation_api_url = "https://tag-validation.internal.example.com"
    tags = {
      ApplicationID    = "APM0001234"
      ApplicationOwner = "jane.doe@example.com"
      BusinessOwner    = "raj.k@example.com"
      CostCenter       = "CC10001"
      WBSCode          = "P-100234.01"
    }
  }
}
