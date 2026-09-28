# Validates the deployment's tags once against ServiceNow/SAP (fails the plan if invalid).
component "tags" {
  source = "./modules/tags"
  inputs = {
    tags               = var.tags
    validation_api_url = var.tag_validation_api_url
  }
  providers = {
    http = provider.http.this
  }
}

# Every AliCloud component consumes the validated map, so it cannot plan without it.
component "network" {
  source = "./modules/network"
  inputs = {
    name       = "app"
    cidr_block = "10.0.0.0/16"
    tags       = component.tags.tags
  }
  providers = {
    alicloud = provider.alicloud.this
  }
}
