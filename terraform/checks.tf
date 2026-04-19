check "github_oidc_needs_repository" {
  assert {
    condition     = !var.create_github_oidc || trimspace(var.github_repository) != ""
    error_message = "When create_github_oidc is true, set github_repository = \"owner/repo\" in terraform.tfvars (see terraform.tfvars.example). Otherwise set create_github_oidc = false."
  }
}
