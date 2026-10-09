variable "github_org" {
  description = "GitHub user or organisation that owns the repos"
  type        = string
}

variable "manage_teams" {
  description = "Manage teams.yaml. Teams only exist in organisations, so keep false on a personal account."
  type        = bool
  default     = false
}

variable "common_variables" {
  description = "Actions variables set on every repo, e.g. AWS_ROLE_ARN, AWS_REGION, GLUE_SCRIPTS_BUCKET, LAMBDA_BUCKET"
  type        = map(string)
  default     = {}
}
