locals {
  repos = yamldecode(file("${path.module}/repos.yaml")).repos
  teams = yamldecode(file("${path.module}/teams.yaml")).teams
}

module "gh_teams" {
  source = "./modules/gh_teams"
  count  = var.manage_teams ? 1 : 0
  teams  = local.teams
}

module "github_repo" {
  source   = "./modules/github_repo"
  for_each = local.repos

  name             = each.key
  config           = each.value
  github_org       = var.github_org
  team_ids         = var.manage_teams ? module.gh_teams[0].team_ids : {}
  common_variables = var.common_variables
}
