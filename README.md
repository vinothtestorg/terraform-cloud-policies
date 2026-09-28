# terraform-cloud-policies

Policy-as-code and governance design for AliCloud infrastructure deployed through HCP Terraform.

## Documents

- [Validating ServiceNow and SAP tag values on AliCloud resources in HCP Terraform](docs/alicloud-tag-validation-options.md): options analysis and recommendation for enforcing mandatory tags (application owner, business owner, cost center, WBS code) at plan and apply time. It covers run tasks, Sentinel/OPA, Terraform-native checks and Alibaba Cloud guardrails.
