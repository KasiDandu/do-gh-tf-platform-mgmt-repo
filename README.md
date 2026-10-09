# do-gh-tf-platform-mgmt-repo

Platform / governance layer. Terraform that manages GitHub itself: every repo listed in
`repos.yaml` is created and configured from here (description, visibility, topics,
template, Actions variables, team access).

`repos.yaml` is the single source of truth. To add a new data pipeline repo, add an entry
with `template_name: do-gh-data-repo-template` and open a PR.

## Layout

```
bootstrap/main.tf            AWS state bucket, artifact buckets, GitHub OIDC role (run once, locally)
modules/gh_teams/            teams + memberships (organisations only)
modules/github_repo/repo.tf  one repo: settings, template, team access, Actions variables
main.tf / providers.tf / variables.tf
repos.yaml                   source of truth for repos
teams.yaml                   teams and members
scripts/import-existing.sh   one-off import of repos that were created with the gh CLI
```

## First-time setup

1. Bootstrap AWS: `cd bootstrap && terraform init && terraform apply -var="github_org=KasiDandu"`.
2. Replace `ACCOUNT_ID` in `providers.tf` with your AWS account ID.
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in the bootstrap outputs.
4. Add repo secret `GH_AUTOMATION_TOKEN` (classic PAT: `repo`, `workflow`, `delete_repo`)
   and repo variables `AWS_ROLE_ARN`, `AWS_REGION` to this repo.
5. Import the repos that already exist, then apply:

```bash
export GITHUB_TOKEN=<your PAT> TF_VAR_github_org=KasiDandu
terraform init
bash scripts/import-existing.sh
terraform plan     # expect: variables added, no repo replaced
terraform apply
```

After that, changes go through PRs: plan on the PR, apply on merge to `main`.

## Personal account vs organisation

Teams only exist in organisations, so `manage_teams` defaults to `false`. In an
organisation, set `manage_teams = true` and add `admin:org` to the token.
