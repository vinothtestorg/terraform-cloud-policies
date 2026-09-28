#!/usr/bin/env bash
# Runs every example's tests. Needs on PATH: terraform (>= 1.16), sentinel, opa, conftest, tfpolicy, python3.
# The golden tags module and the Terraform policy tests call a local mock of the Tag Validation Service.
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"

python3 mock-api/mock_tag_api.py 18080 &
MOCK_PID=$!
trap 'kill "$MOCK_PID" 2>/dev/null || true' EXIT
sleep 1

step() { printf '\n==> %s\n' "$1"; }

step "Stack configuration (terraform stacks validate)"
(cd stack && terraform stacks init >/dev/null && terraform stacks validate)

step "Golden tags module (terraform test against the mock API)"
(cd stack/modules/tags && terraform init -input=false >/dev/null && terraform test)

step "PR conformance check (conftest): good fixtures and the Stack's network module must pass"
conftest test --parser hcl2 --data conformance/data -p conformance/policy \
  conformance/fixtures/good.tf stack/modules/network/main.tf

step "PR conformance check (conftest): bad fixtures must fail"
if conftest test --parser hcl2 --data conformance/data -p conformance/policy conformance/fixtures/bad.tf; then
  echo "expected conformance failures were not reported" >&2
  exit 1
fi

step "Terraform policy, beta (tfpolicy test)"
(cd terraform-policy && tfpolicy test --policies=policies --tests=tests --input-file=tests/test.tfvars)

step "Alibaba Cloud tag policy + Cloud Config (terraform validate)"
(cd alibaba-tag-policy && terraform init -input=false >/dev/null && terraform validate)

step "Workspaces: Sentinel policy (sentinel test)"
(cd workspaces/sentinel && sentinel test)

step "Workspaces: OPA policy (opa test)"
(cd workspaces/opa && opa test . -v)

step "Workspaces: run task handler (fake HCP Terraform API)"
(cd workspaces/run-task && python3 test_runtask.py)

cd "$ROOT"
printf '\nAll example tests passed.\n'
