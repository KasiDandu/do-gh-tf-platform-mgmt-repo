variable "name" {
  type = string
}

variable "config" {
  type = any
}

variable "github_org" {
  type = string
}

variable "team_ids" {
  type    = map(string)
  default = {}
}

variable "common_variables" {
  type    = map(string)
  default = {}
}

locals {
  template  = try(var.config.template_name, null)
  variables = merge(var.common_variables, try(var.config.variables, {}))
  teams     = { for team, permission in try(var.config.teams, {}) : team => permission if length(var.team_ids) > 0 }
}

resource "github_repository" "this" {
  name                   = var.name
  description            = try(var.config.description, null)
  visibility             = try(var.config.visibility, "public")
  is_template            = try(var.config.is_template, false)
  topics                 = try(var.config.topics, [])
  auto_init              = local.template == null
  delete_branch_on_merge = true

  dynamic "template" {
    for_each = local.template == null ? [] : [local.template]
    content {
      owner      = var.github_org
      repository = template.value
    }
  }

  lifecycle {
    # Creation-only settings. Ignored so repos imported by scripts/import-existing.sh
    # are not replaced.
    ignore_changes = [auto_init, template]
  }
}

resource "github_team_repository" "this" {
  for_each   = local.teams
  team_id    = var.team_ids[each.key]
  repository = github_repository.this.name
  permission = each.value
}

resource "github_actions_variable" "this" {
  for_each      = local.variables
  repository    = github_repository.this.name
  variable_name = each.key
  value         = each.value
}

# Only needed for private repos whose reusable workflows other repos call.
resource "github_actions_repository_access_level" "this" {
  count        = try(var.config.actions_access, null) == null ? 0 : 1
  repository   = github_repository.this.name
  access_level = var.config.actions_access
}
