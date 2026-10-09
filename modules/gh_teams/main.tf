variable "teams" {
  type = any
}

resource "github_team" "this" {
  for_each    = var.teams
  name        = each.key
  description = try(each.value.description, null)
  privacy     = try(each.value.privacy, "closed")
}

locals {
  memberships = merge([
    for team, cfg in var.teams : merge(
      { for u in try(cfg.maintainers, []) : "${team}:${u}" => { team = team, user = u, role = "maintainer" } },
      { for u in try(cfg.members, []) : "${team}:${u}" => { team = team, user = u, role = "member" } }
    )
  ]...)
}

resource "github_team_membership" "this" {
  for_each = local.memberships
  team_id  = github_team.this[each.value.team].id
  username = each.value.user
  role     = each.value.role
}

output "team_ids" {
  value = { for k, t in github_team.this : k => t.id }
}
