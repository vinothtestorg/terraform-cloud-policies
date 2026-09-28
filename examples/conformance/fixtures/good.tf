resource "alicloud_vpc" "ok" {
  cidr_block = "10.0.0.0/16"
  tags       = var.tags
}

resource "alicloud_vswitch" "ok_merge" {
  vpc_id     = alicloud_vpc.ok.id
  cidr_block = "10.0.1.0/24"
  tags       = merge({ Name = "app" }, var.tags)
}

resource "alicloud_security_group_rule" "untaggable" {
  type = "ingress"
}
