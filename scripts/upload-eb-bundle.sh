#!/usr/bin/env bash
# Zip target/application.jar and upload to the CloudFormation deployments bucket.
# Usage: ./scripts/upload-eb-bundle.sh [version-label]   (default: v1 — must match eb_version_label in terraform.tfvars)
# Prerequisites: terraform apply (deploy_eb_environment=false), mvn -B package, aws CLI configured.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f target/application.jar ]]; then
  echo "Run: mvn -B package   (expected target/application.jar)"
  exit 1
fi

VERSION_LABEL="${1:-v1}"
KEY="releases/${VERSION_LABEL}.zip"
TMP="$(mktemp).zip"
zip -j "$TMP" target/application.jar

BUCKET="$(terraform -chdir=terraform output -raw deployments_s3_bucket)"
aws s3 cp "$TMP" "s3://${BUCKET}/${KEY}"
rm -f "$TMP"

echo "Uploaded s3://${BUCKET}/${KEY}"
echo "Next: set deploy_eb_environment = true in terraform/terraform.tfvars (eb_version_label = \"${VERSION_LABEL}\"), set eb_solution_stack_override if needed, then: cd terraform && terraform apply"
