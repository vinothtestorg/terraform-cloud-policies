module "tag_reference" {
  source = "./modules/tag_reference.sentinel"
}

policy "enforce-alicloud-mandatory-tags" {
  source            = "./enforce-alicloud-mandatory-tags.sentinel"
  enforcement_level = "hard-mandatory"
}
