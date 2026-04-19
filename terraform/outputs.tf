output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = var.aws_region
}

output "cloudformation_stack_name" {
  description = "Root stack — open this in the CloudFormation console to see resources, events, and drift."
  value       = aws_cloudformation_stack.task_management.name
}

output "cloudformation_stack_id" {
  value = aws_cloudformation_stack.task_management.id
}

output "rds_address" {
  value = aws_cloudformation_stack.task_management.outputs["RdsAddress"]
}

output "rds_port" {
  value = aws_cloudformation_stack.task_management.outputs["RdsPort"]
}

output "database_username" {
  value = var.db_username
}

output "database_name" {
  value = var.db_name
}

output "database_password" {
  description = "RDS master password (also passed to EB env in dev/demo)."
  value       = random_password.db.result
  sensitive   = true
}

output "elastic_beanstalk_application_name" {
  value = aws_cloudformation_stack.task_management.outputs["ElasticBeanstalkApplicationName"]
}

output "deployments_s3_bucket" {
  value = aws_cloudformation_stack.task_management.outputs["DeploymentsBucketName"]
}

output "eb_environment_name" {
  description = "For deploy-aws.yml variable EB_ENVIRONMENT_NAME."
  value       = try(aws_cloudformation_stack.task_management.outputs["EbEnvironmentName"], "")
}

output "eb_environment_cname" {
  description = "Load balancer URL (empty until EB environment exists)."
  value       = try(aws_cloudformation_stack.task_management.outputs["EbEnvironmentCname"], "")
}

output "github_actions_deploy_role_arn" {
  description = "GitHub Actions secret AWS_ROLE_TO_ASSUME — IAM role ARN (…:role/…), not a user ARN. Empty if OIDC resources were not created."
  value       = try(aws_cloudformation_stack.task_management.outputs["GithubActionsDeployRoleArn"], "")
}

output "github_actions_oidc_help" {
  description = "Read this if github_actions_deploy_role_arn is empty."
  value       = <<-EOT
    No role ARN usually means either github_repository was empty in terraform.tfvars or create_github_oidc was false, so CloudFormation did not create the GitHub OIDC role.
    Fix: set github_repository = "YOUR_ORG/YOUR_REPO" and create_github_oidc = true, then run terraform apply.
    Or in AWS: CloudFormation → your stack (see cloudformation_stack_name output) → Outputs tab → copy GithubActionsDeployRoleArn.
    EOT
}
