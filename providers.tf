terraform {
  required_version = ">= 1.10"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "kasidandu-tf-state-870276621986"
    key          = "github/platform-mgmt.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

# Authenticates with the GITHUB_TOKEN environment variable (the PAT in CI).
provider "github" {
  owner = var.github_org
}
