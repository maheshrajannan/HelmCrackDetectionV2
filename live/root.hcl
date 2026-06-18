# Root Terragrunt config — included by every environment under live/.
# Owns the backend: generates backend.tf in each unit, so modules never hardcode state config.
# (Named root.hcl, not terragrunt.hcl, so `terragrunt run-all` doesn't treat it as a runnable unit.)

remote_state {
  backend = "gcs"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }

  config = {
    bucket = "crack-detection-terraform"      # existing bucket used by terraform/gcp-mahesh
    prefix = "gke/terraform"                  # matches existing state prefix -> adopts current state, zero migration
    # NOTE: when adding a second environment, switch prefix to
    # "${path_relative_to_include()}/terraform" so each env gets its own state,
    # and migrate this one with `terraform state pull/push` or terragrunt init -migrate-state.
  }
}
