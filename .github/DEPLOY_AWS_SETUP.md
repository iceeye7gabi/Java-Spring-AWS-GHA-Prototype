# GitHub Actions — deploy to AWS (Elastic Beanstalk)

Workflow file: [`.github/workflows/deploy-aws.yml`](../.github/workflows/deploy-aws.yml)

You need **either** OIDC (recommended, **one** secret) **or** a static IAM user (**two** secrets).

---

## 1. Repository variables (non-secret)

In GitHub: **Settings → Secrets and variables → Actions → Variables → New repository variable**

| Variable | Example | Where to get it |
|----------|---------|-----------------|
| `AWS_REGION` | `eu-central-1` | Same region you used in Terraform. **If you omit it**, the workflow defaults to **`eu-central-1`**. |
| `EB_S3_BUCKET` | `task-management-dev-eb-abc123` | `terraform output -raw deployments_s3_bucket` |
| `EB_APPLICATION_NAME` | `task-management-dev-app` | `terraform output -raw elastic_beanstalk_application_name` |
| `EB_ENVIRONMENT_NAME` | `task-management-dev-env` | `terraform output -raw eb_environment_name` |

---

## Option A — OIDC (recommended, no long-lived AWS keys)

Terraform should have created an IAM role (if `create_github_oidc = true` and `github_repository` is set).

You must give the workflow the **role ARN** in **one** of these ways:

### A1 — Repository **secret** (hidden in logs)

| Name | Value |
|------|--------|
| `AWS_ROLE_TO_ASSUME` | `terraform output -raw github_actions_deploy_role_arn` (must be `…:role/…`, not `…:user/…`) |

### A2 — Repository **variable** (bypasses storing the ARN as a secret)

| Name | Value |
|------|--------|
| `AWS_DEPLOY_ROLE_ARN` | Same role ARN as above |

The ARN is **not** a password; it’s only useful together with GitHub’s OIDC token. Using a **variable** avoids creating a secret, but anyone with repo access can read it (fine for many private repos).

If `terraform output` is empty, the role wasn’t created: set `github_repository` and `create_github_oidc = true` in `terraform.tfvars`, run `terraform apply`, or copy **`GithubActionsDeployRoleArn`** from **CloudFormation → your stack → Outputs**.

### Precedence

If both `AWS_ROLE_TO_ASSUME` (secret) and `AWS_DEPLOY_ROLE_ARN` (variable) are set, the **secret** wins.

### Do **not** set

`AWS_AUTH_MODE` (leave unset or anything other than `static`).

### Trust policy note

The role trusts **this repository only** (as set in `terraform.tfvars`: `github_repository`, `github_branch_ref`). Pushes from forks do not get credentials unless you change IAM.

---

## Option B — Static IAM user (**two** secrets)

Use this if you cannot use OIDC (e.g. no permission to add the GitHub OIDC provider).

### 1. IAM user in AWS

Create an IAM user with an **inline or attached policy** that allows at least:

- `elasticbeanstalk:CreateApplicationVersion`, `UpdateEnvironment`, `DescribeEnvironments`, `DescribeApplicationVersions`, `DescribeApplications` (scoped or `*` for a sandbox)
- `s3:PutObject`, `s3:GetObject`, `s3:ListBucket` on your **deployments** bucket and `s3://bucket/*`

### 2. Repository secrets

| Name | Value |
|------|--------|
| `AWS_ACCESS_KEY_ID` | Access key ID for that user |
| `AWS_SECRET_ACCESS_KEY` | Secret access key |

### 3. Repository variable

| Name | Value |
|------|--------|
| `AWS_AUTH_MODE` | `static` |

### Do **not** set `AWS_ROLE_TO_ASSUME` for this path (or leave it empty).

**Security:** rotate keys if leaked; prefer Option A for production.

---

## 3. Run the workflow

**Actions** → **Deploy to AWS (Elastic Beanstalk)** → **Run workflow** (this workflow is **manual-only**; it does not run on push).

---

## 4. Prerequisites in AWS

- Terraform applied with **`deploy_eb_environment = true`** so the EB environment exists.
- Bundle path in S3: workflow uploads to `releases/<github-sha>.zip` (same pattern as local deploys; version label is the full commit SHA).

---

## 5. Troubleshooting

| Issue | What to check |
|-------|----------------|
| `Credentials could not be loaded` / `Could not load credentials from any providers` | **Secret `AWS_ROLE_TO_ASSUME` is missing or empty.** Add it under **Settings → Secrets and variables → Actions → Secrets**. Value must be the **full role ARN** (starts with `arn:aws:iam::…:role/…`). |
| `Could not assume role` / `AccessDenied` on `sts:AssumeRoleWithWebIdentity` | IAM trust policy must allow GitHub’s OIDC for **this repo**. After pulling the latest template, run **`terraform apply`** so the role’s `sub` condition allows `repo:YOUR_ORG/YOUR_REPO:*` (any branch). Or edit the role in IAM → **Trust relationships** to match. |
| `Access Denied` on S3/EB | IAM **permissions** on the role include your bucket ARN and Elastic Beanstalk actions. |
| Missing variables | All four variables in section 1 are set (names are case-sensitive). |
