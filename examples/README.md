# Reference implementations

These examples back the recommendations in [`docs/alicloud-tag-validation-options.md`](../docs/alicloud-tag-validation-options.md). They are starting points to adapt, not production code: hostnames, account IDs and tag values are placeholders.

| Path | Option | What it shows |
|---|---|---|
| [`stack/`](stack/) | 1 | HCP Terraform Stack where a `tags` component validates the deployment's tags and every AliCloud component consumes `component.tags.tags` |
| [`stack/modules/tags/`](stack/modules/tags/) | 1 | Golden tags module: typed tags, format validation, `data "http"` call to the Tag Validation Service, postcondition; `terraform test` suite |
| [`conformance/`](conformance/) | 1 | `conftest` PR check that taggable `alicloud_*` resources use `tags = var.tags` (or `merge(<extras>, var.tags)`); taggable list generated from the provider schema |
| [`terraform-policy/`](terraform-policy/) | 3 | Terraform policy (**beta**) for Stacks: presence, membership and relationship checks with one live lookup; fails closed |
| [`alibaba-tag-policy/`](alibaba-tag-policy/) | 4 | `alicloud_tag_policy` (allow-lists + regex) and Cloud Config `required-tags`, rendered from the daily snapshot |
| [`workspaces/`](workspaces/) | workspaces | Run task handler, Sentinel policy set and OPA policy set, for any infrastructure that stays on HCP Terraform workspaces |
| [`tag-reference/`](tag-reference/) | all | Sample of the daily ServiceNow/SAP snapshot |
| [`mock-api/`](mock-api/) | tests | Local stand-in for the Tag Validation Service (`POST /v1/tags/validate`, `GET /v1/tag-reference`) |

## Run the tests

```shell
./run-tests.sh
```

The script starts the mock API on `127.0.0.1:18080`, then runs each check. It needs these tools on `PATH`; these are the versions they were last run with:

| Tool | Version |
|---|---|
| Terraform (incl. `terraform stacks`) | 1.16.4 |
| Sentinel | 0.41.0 (also passes on 0.40.0) |
| OPA | 1.21.0 |
| Conftest | 0.70.1 |
| tfpolicy | 0.3.0 |
| Python | 3.11 |

Providers resolved from the Terraform Registry: `aliyun/alicloud` 1.293.0 and `hashicorp/http` 3.6.2.

## Notes

- **Stack lock file:** `stack/.terraform.lock.hcl` is committed because a Stack cannot run without one. Regenerate it with `terraform stacks init -upgrade` after changing provider versions.
- **Taggable resource list:** after a provider upgrade, regenerate `conformance/data/alicloud_taggable.json` from a directory initialised with the AliCloud provider:
  `terraform providers schema -json | python3 conformance/scripts/generate_taggable.py > conformance/data/alicloud_taggable.json`
- **Terraform policy (beta):** in `tfpolicy` 0.3.0 the second argument of `core::gethttprequest` is the header map itself, and `tfpolicy validate` cannot take inputs, so use `tfpolicy test` (which validates first).
- **Workspaces vs Stacks:** Sentinel, OPA and run tasks do not apply to HCP Terraform Stacks; they are here for workspaces only.
