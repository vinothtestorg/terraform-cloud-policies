# terraform-cloud-policies

Policy-as-code and governance design for AliCloud infrastructure deployed through HCP Terraform Stacks.

## Documents

- [Validating ServiceNow and SAP tag values on AliCloud with HCP Terraform Stacks](docs/alicloud-tag-validation-options.md): options analysis and recommendation for enforcing mandatory tags (application owner, business owner, cost center, WBS code) at plan and apply time. It covers component-level validation, a Stacks API approval gate, Terraform policy (beta) and Alibaba Cloud guardrails, plus workspace options.
- [Reference implementations](examples/README.md): tested examples for each option. Run `examples/run-tests.sh`.
