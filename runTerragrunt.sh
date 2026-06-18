#!/usr/bin/env bash
# runTerragrunt.sh — drive the Terragrunt setup for the mahesh environment.
#
# Usage:
#   ./runTerragrunt.sh           # init + plan (safe, default)
#   ./runTerragrunt.sh plan      # same as default
#   ./runTerragrunt.sh apply     # init + apply (asks for confirmation)
#   ./runTerragrunt.sh destroy   # tear down (asks for confirmation)
#   ./runTerragrunt.sh output    # show outputs (e.g. kubectl_config)
#
# First successful check: `plan` should report "No changes" — Terragrunt is
# adopting the existing state at gs://crack-detection-terraform/gke/terraform.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${REPO_ROOT}/live/mahesh"
ACTION="${1:-plan}"

# --- Preflight ---------------------------------------------------------------
for tool in terraform terragrunt gcloud; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: '$tool' not found. Install it first (e.g. 'brew install $tool')." >&2
    exit 1
  fi
done

if ! gcloud auth application-default print-access-token >/dev/null 2>&1; then
  echo "ERROR: no Application Default Credentials. Run:" >&2
  echo "  gcloud auth application-default login" >&2
  exit 1
fi

[ -d "$ENV_DIR" ] || { echo "ERROR: $ENV_DIR not found." >&2; exit 1; }

echo "==> Environment : live/mahesh"
echo "==> Module      : terraform/gcp-mahesh"
echo "==> Action      : $ACTION"
cd "$ENV_DIR"

# --- Run ---------------------------------------------------------------------
terragrunt init

case "$ACTION" in
  plan)
    terragrunt plan
    echo ""
    echo "==> If the plan shows 'No changes', Terragrunt adopted the existing state correctly."
    ;;
  apply)
    terragrunt apply   # interactive confirmation
    echo ""
    echo "==> Get kubeconfig with: ./runTerragrunt.sh output"
    ;;
  destroy)
    terragrunt destroy # interactive confirmation
    ;;
  output)
    terragrunt output -raw kubectl_config 2>/dev/null || terragrunt output
    ;;
  *)
    echo "ERROR: unknown action '$ACTION' (use plan | apply | destroy | output)" >&2
    exit 1
    ;;
esac
