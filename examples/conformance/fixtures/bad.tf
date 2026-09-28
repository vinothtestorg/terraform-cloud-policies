resource "alicloud_instance" "inline" {
  instance_type = "ecs.g7.large"
  tags          = { CostCenter = "CC10001" }
}

resource "alicloud_oss_bucket" "missing" {
  bucket = "app-logs"
}

resource "alicloud_vpc" "override" {
  cidr_block = "10.0.0.0/16"
  tags       = merge(var.tags, { CostCenter = "CC99999" })
}
