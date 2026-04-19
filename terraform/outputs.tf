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
  description = "GitHub Actions: repository secret AWS_ROLE_TO_ASSUME (empty if OIDC not created)."
  value       = try(aws_cloudformation_stack.task_management.outputs["GithubActionsDeployRoleArn"], "")
}
