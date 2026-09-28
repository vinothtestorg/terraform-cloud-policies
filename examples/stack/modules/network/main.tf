terraform {
  required_providers {
    alicloud = {
      source = "aliyun/alicloud"
    }
  }
}

variable "name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "tags" {
  description = "Validated tag map from component.tags - never build tags inline."
  type        = map(string)
}

resource "alicloud_vpc" "this" {
  vpc_name   = var.name
  cidr_block = var.cidr_block
  tags       = var.tags
}
