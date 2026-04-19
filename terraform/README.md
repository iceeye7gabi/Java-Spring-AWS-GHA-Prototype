# Terraform — AWS (Elastic Beanstalk + RDS)

Infrastructure is defined in **`cloudformation/task-management.yaml`** and deployed as **one root stack** named like `task-management-dev-stack`. Terraform’s only AWS resource is **`aws_cloudformation_stack`**, so in the **CloudFormation** console you get a single stack with **Events**, **Resources**, **Outputs**, and **failed rollback** visibility.

This stack targets a **small, cost-conscious** footprint: **default VPC**, **RDS PostgreSQL `db.t3.micro`**, **Elastic Beanstalk** on **`t3.micro`**, and an **S3 bucket** for application bundles. These sizes are commonly covered by the **AWS Free Tier for new accounts** (typically **12 months** for EC2/RDS within limits). Always confirm in the [AWS Free Tier](https://aws.amazon.com/free/) page and **Billing → Cost Explorer**; mis-sized resources or regions can still incur charges.

## What you need (do not paste secrets into chat)

1. An **AWS account** and an IAM identity allowed to create RDS, EB, S3, IAM, and VPC-related resources.
2. **AWS credentials** on your machine via **one** of:
   - `aws configure` (creates `~/.aws/credentials`), or  
   - Environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` (if using temporary creds), or  
   - An **IAM role** if you run Terraform from CI (advanced).
3. **Region** (e.g. `eu-central-1`) — set in `terraform.tfvars` or `TF_VAR_aws_region`.
4. **GitHub repository** string for OIDC (format `owner/repo`), only if `create_github_oidc = true`.

**Never** commit `terraform.tfvars`, `.tfstate`, or share access keys in issues, chat, or screenshots.

## Local machine: AWS CLI + Terraform (what to run)

The Cursor/cloud environment used for automation **does not include the AWS CLI** and **cannot** run `aws configure` with your keys. Run everything below **on your laptop** (or in CI with OIDC).

### 1. Install tools

- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (e.g. macOS: `brew install awscli`)
- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5 (e.g. `brew install terraform`)

### 2. Configure AWS credentials (`aws configure`)

Create or use an IAM user/role with permission to manage RDS, Elastic Beanstalk, S3, IAM, EC2/VPC (read default VPC). Then run:

```bash
aws configure
```

You will be prompted for four values:

| Prompt | What to enter |
|--------|----------------|
| **AWS Access Key ID** | From IAM → Users → Security credentials → Access keys (or from your SSO/admin). |
| **AWS Secret Access Key** | Shown only once when the key is created. |
| **Default region name** | `eu-central-1` (must match `aws_region` in `terraform.tfvars`). |
| **Default output format** | `json` (recommended) or leave default. |

This writes `~/.aws/credentials` and `~/.aws/config`. **Alternative:** export `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and optionally `AWS_SESSION_TOKEN` instead of storing keys in files.

Verify the identity and region:

```bash
aws sts get-caller-identity
# Expect "Account" to match your 12-digit AWS account ID
```

### 3. Prepare Terraform variables from the template

```bash
cd path/to/Java-Spring-AWS-GHA-Prototype/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: aws_region, github_repository, deploy_eb_environment, etc.
```

### 4. Run Terraform

```bash
terraform init
terraform plan
terraform apply
```

Use the same shell session (or the same `AWS_PROFILE`) so Terraform picks up the credentials `aws configure` stored.

## First apply (stack without EB environment)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars (region, github_repository, deploy_eb_environment = false, …)

terraform init
terraform plan
terraform apply
```

With `deploy_eb_environment = false`, the CloudFormation stack creates **RDS**, **S3**, **EB application**, **IAM** for EB instances, and optionally **GitHub OIDC** — **not** the EB application version or environment (no JAR required yet). Open **CloudFormation → Stacks → `…-stack`** to watch progress and troubleshoot.

## Upload the app bundle (required before EB)

Terraform does **not** upload the JAR (avoids dependency cycles with the stack). After the first apply and a successful build:

```bash
cd ..   # repo root
mvn -B package
./scripts/upload-eb-bundle.sh v1   # must match eb_version_label in terraform.tfvars
```

This zips `target/application.jar` and runs `aws s3 cp` to `s3://<bucket>/releases/v1.zip`.

## Second apply (enable Elastic Beanstalk in the stack)

In `terraform.tfvars`:

```hcl
deploy_eb_environment = true
eb_version_label      = "v1"   # same label used for the upload
# Optional if auto-detection fails:
# eb_solution_stack_override = "64bit Amazon Linux 2023 v…. running Corretto 21"
```

Then:

```bash
cd terraform
terraform apply
```

CloudFormation creates the **application version** and **environment** inside the **same stack** (check **Resources** and **Events** in the console).

## Outputs useful for GitHub Actions

After apply:

```bash
terraform output cloudformation_stack_name
terraform output github_actions_deploy_role_arn
terraform output deployments_s3_bucket
terraform output elastic_beanstalk_application_name
terraform output eb_environment_name
terraform output eb_environment_cname
```

Configure GitHub **secrets and variables** as described in [`.github/DEPLOY_AWS_SETUP.md`](../.github/DEPLOY_AWS_SETUP.md) (OIDC = one secret, or static IAM = two secrets).

## Destroy

```bash
cd terraform
terraform destroy
```

This deletes the **CloudFormation stack** and (via the template) the resources it owns.

## Migrating from the older “all Terraform resources” layout

If you previously applied **without** a nested stack, run **`terraform destroy`** with the **old** configuration (or remove old resources from state) before switching to this version, or you will get duplicate resource name conflicts.

## Elastic Beanstalk: “Your query returned no results” (solution stack)

AWS renames platform stacks by region and over time. The template auto-picks the newest stack whose name matches **`eb_solution_stack_name_regex`** (default `Corretto 21`) when **`deploy_eb_environment`** is true and **`eb_solution_stack_override`** is empty.

If `terraform apply` still fails:

1. List stacks in **your** region (e.g. `eu-central-1`):

   ```bash
   aws elasticbeanstalk list-available-solution-stacks \
     --region eu-central-1 \
     --output table \
     --query "SolutionStacks[?contains(SolutionStackName, \`Corretto 21\`)].SolutionStackName"
   ```

2. Copy the **full** string (e.g. `64bit Amazon Linux 2023 v…. running Corretto 21`) into **`eb_solution_stack_override`** in `terraform.tfvars` and apply again.

**Note:** The solution stack data source runs **only** when you create the EB environment (`deploy_eb_environment = true`) and leave the override empty, so a first apply with `deploy_eb_environment = false` does not need a matching stack.

## If GitHub OIDC provider already exists

If `terraform apply` errors because an OIDC provider for `token.actions.githubusercontent.com` already exists in the account, either **import** it or set `create_github_oidc = false` and define an IAM role manually with the same trust policy.
