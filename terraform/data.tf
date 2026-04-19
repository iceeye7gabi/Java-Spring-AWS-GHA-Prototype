data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Only when deploy_eb_environment is true and eb_solution_stack_override is empty (see cfn_stack.tf).
data "aws_elastic_beanstalk_solution_stack" "java" {
  count = var.deploy_eb_environment && var.eb_solution_stack_override == "" ? 1 : 0

  name_regex  = var.eb_solution_stack_name_regex
  most_recent = true
}
