#!/usr/bin/env bash
# One-off: bring repos created with the gh CLI under Terraform management.
# Run from the repo root after `terraform init` and before the first `terraform apply`.
# Needs GITHUB_TOKEN and TF_VAR_github_org in the environment.
set -euo pipefail

tf_import() {
  terraform state show "$1" >/dev/null 2>&1 || terraform import "$1" "$2"
}

for repo in do-gh-shared-actions do-aws-tf-process-pipeline-bp do-aws-pipeline-infra \
  do-gh-data-repo-template do-aws-lakehouse-process-storage-ppi-triage; do
  tf_import "module.github_repo[\"$repo\"].github_repository.this" "$repo"
done

pipeline=do-aws-lakehouse-process-storage-ppi-triage
for var in DATA_PIPELINE BLUEPRINT_TYPE ENABLE_GLUE ENABLE_LAMBDA; do
  tf_import "module.github_repo[\"$pipeline\"].github_actions_variable.this[\"$var\"]" "$pipeline:$var"
done
