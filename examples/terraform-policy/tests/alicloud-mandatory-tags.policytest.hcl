policytest {
  targets = ["../policies/alicloud-mandatory-tags.policy.hcl"]
}

inputs {
  tag_reference_url   = "http://127.0.0.1:18080/v1/tag-reference"
  tag_reference_token = "test-token"
}

resource "alicloud_vpc" "valid" {
  attrs = {
    vpc_name = "app"
    tags = {
      ApplicationID    = "APM0001234"
      ApplicationOwner = "Jane.Doe@example.com"
      BusinessOwner    = "raj.k@example.com"
      CostCenter       = "CC10001"
      WBSCode          = "P-100234.01"
    }
  }
}

resource "alicloud_vswitch" "missing_tags" {
  expect_failure = true
  attrs = {
    vswitch_name = "app"
    tags = {
      ApplicationID = "APM0001234"
    }
  }
}

resource "alicloud_oss_bucket" "null_tags" {
  expect_failure = true
  attrs = {
    bucket = "app"
    tags   = null
  }
}

resource "alicloud_instance" "wrong_owner_and_wbs" {
  expect_failure = true
  attrs = {
    instance_name = "app"
    tags = {
      ApplicationID    = "APM0005678"
      ApplicationOwner = "jane.doe@example.com"
      BusinessOwner    = "ana.s@example.com"
      CostCenter       = "CC20002"
      WBSCode          = "P-100234.01"
    }
  }
}

resource "alicloud_db_instance" "unknown_cost_center" {
  expect_failure = true
  attrs = {
    engine = "MySQL"
    tags = {
      ApplicationID    = "APM0001234"
      ApplicationOwner = "jane.doe@example.com"
      BusinessOwner    = "raj.k@example.com"
      CostCenter       = "CC99999"
      WBSCode          = "P-100234.01"
    }
  }
}

# Not taggable: no tags attribute, so the policies do not apply.
resource "alicloud_security_group_rule" "untaggable" {
  attrs = {
    type = "ingress"
  }
}
