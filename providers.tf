terraform {
  required_version = ">= 1.10"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "kasidandu-tf-state-ACCOUNT_ID" # TODO: replace ACCOUNT_ID after bootstrap
    key          = "github/platform-mgmt.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}

# Authenticates with the GITHUB_TOKEN environment variable (the PAT in CI).
provider "github" {
  owner = var.github_org
}
