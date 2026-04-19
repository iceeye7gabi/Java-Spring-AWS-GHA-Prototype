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

## Option A — OIDC (recommended, **one** secret)

No long-lived AWS keys in GitHub. Terraform should have created an IAM role (if `create_github_oidc = true`).

### Secret

| Name | Value |
|------|--------|
| `AWS_ROLE_TO_ASSUME` | Output of `terraform output -raw github_actions_deploy_role_arn` (full ARN, starts with `arn:aws:iam::…:role/…`) |

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
| `Could not assume role` (OIDC) | Role trust policy matches `repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main`; run from default branch first. |
| `Access Denied` on S3/EB | IAM policy for the role/user includes your bucket ARN and EB application/env names. |
| Missing variables | All four variables in section 1 are set (names are case-sensitive). |
