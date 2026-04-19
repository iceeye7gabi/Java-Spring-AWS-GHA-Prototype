locals {
  solution_stack_for_cfn = var.deploy_eb_environment ? (
    var.eb_solution_stack_override != "" ? var.eb_solution_stack_override : data.aws_elastic_beanstalk_solution_stack.java[0].name
  ) : ""
}

resource "aws_cloudformation_stack" "task_management" {
  name = "${local.prefix}-stack"

  template_body = file("${path.module}/cloudformation/task-management.yaml")

  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
  on_failure   = "ROLLBACK"

  parameters = {
    ProjectName         = var.project_name
    Environment         = var.environment
    VpcId               = data.aws_vpc.default.id
    SubnetIds           = join(",", sort(tolist(data.aws_subnets.default.ids)))
    VpcCidrBlock        = data.aws_vpc.default.cidr_block
    DatabaseName        = var.db_name
    DatabaseUsername    = var.db_username
    DatabasePassword    = random_password.db.result
    RdsInstanceClass    = var.rds_instance_class
    RdsAllocatedStorage = tostring(var.rds_allocated_storage)
    EbInstanceType      = var.eb_instance_type

    DeployEbEnvironment = var.deploy_eb_environment ? "true" : "false"
    SolutionStackName   = local.solution_stack_for_cfn
    SourceBundleS3Key   = var.deploy_eb_environment ? "releases/${var.eb_version_label}.zip" : ""
    EbVersionLabel      = var.eb_version_label

    CreateGithubOidc = local.create_oidc ? "true" : "false"
    GithubRepository = var.github_repository
    GithubBranchRef  = var.github_branch_ref
  }
}
