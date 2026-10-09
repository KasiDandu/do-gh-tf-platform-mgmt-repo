terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "github_org" {
  description = "GitHub user or organisation that owns the repos (case as shown on GitHub)"
  type        = string
}

data "aws_caller_identity" "current" {}

locals {
  # S3 bucket names must be lowercase.
  prefix = lower(var.github_org)
  suffix = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "${local.prefix}-tf-state-${local.suffix}"
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "glue_scripts" {
  bucket        = "${local.prefix}-glue-scripts-${local.suffix}"
  force_destroy = true
}

resource "aws_s3_bucket" "lambda_artifacts" {
  bucket        = "${local.prefix}-lambda-artifacts-${local.suffix}"
  force_destroy = true
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-deployer"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

# Practice only: broad permissions keep this short. Narrow it for real use.
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "tf_state_bucket" {
  value = aws_s3_bucket.tf_state.bucket
}

output "glue_scripts_bucket" {
  value = aws_s3_bucket.glue_scripts.bucket
}

output "lambda_bucket" {
  value = aws_s3_bucket.lambda_artifacts.bucket
}

output "role_arn" {
  value = aws_iam_role.github_actions.arn
}
