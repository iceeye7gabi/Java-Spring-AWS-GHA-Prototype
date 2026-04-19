variable "aws_region" {
  description = "AWS region (e.g. eu-central-1). Pick one that supports the resources you need."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Short name used for resource names (letters, numbers, hyphens)."
  type        = string
  default     = "task-management"
}

variable "environment" {
  description = "Deployment stage label (e.g. dev, prod)."
  type        = string
  default     = "dev"
}

# --- Free-tier oriented defaults (new AWS accounts: 12-month EC2/RDS free tier) ---

variable "eb_instance_type" {
  description = "EC2 instance type for Elastic Beanstalk workers. t3.micro is free-tier eligible for new accounts (limits apply)."
  type        = string
  default     = "t3.micro"
}

variable "rds_instance_class" {
  description = "RDS instance class. db.t3.micro is typically free-tier eligible for PostgreSQL (new accounts, 12 months)."
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB (free tier often includes 20 GB General Purpose)."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "taskdb"
}

variable "db_username" {
  description = "PostgreSQL master username."
  type        = string
  default     = "taskadmin"
}

# GitHub OIDC (optional — set create_github_oidc = true and fill github_repository)

variable "create_github_oidc" {
  description = "If true, creates an IAM role GitHub Actions can assume via OIDC (no long-lived AWS keys in GitHub)."
  type        = bool
  default     = true
}

variable "github_repository" {
  description = "GitHub repo allowed to assume the deploy role, format: ORG/REPO (e.g. iceeye7gabi/Java-Spring-AWS-GHA-Prototype)."
  type        = string
  default     = ""
}

variable "github_branch_ref" {
  description = "Restrict OIDC to this branch ref (e.g. refs/heads/main)."
  type        = string
  default     = "refs/heads/main"
}

variable "deploy_eb_environment" {
  description = "When true, zips the built JAR and creates an EB application version + environment. Requires target/application.jar (run mvn package first)."
  type        = bool
  default     = false
}

variable "application_jar_path" {
  description = "Optional absolute or module-relative path to application.jar. Defaults to ../target/application.jar next to this repo."
  type        = string
  nullable    = true
  default     = null
}

variable "eb_version_label" {
  description = "Elastic Beanstalk application version label (change when uploading a new bundle)."
  type        = string
  default     = "v1"
}

variable "eb_solution_stack_override" {
  description = "Exact EB solution stack name for your region (from: aws elasticbeanstalk list-available-solution-stacks). Leave empty to auto-select the newest stack matching eb_solution_stack_name_regex when deploy_eb_environment is true."
  type        = string
  default     = ""
}

variable "eb_solution_stack_name_regex" {
  description = "Substring/regex to match available stacks when override is empty. If plan still fails, set eb_solution_stack_override to the full name from AWS."
  type        = string
  default     = "Corretto 21"
}
