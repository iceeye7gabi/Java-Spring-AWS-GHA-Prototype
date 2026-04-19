locals {
  prefix = "${var.project_name}-${var.environment}"

  create_oidc = var.create_github_oidc && var.github_repository != ""
}
