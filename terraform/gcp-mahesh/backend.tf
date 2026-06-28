terraform {
  backend "gcs" {
    # bucket is intentionally omitted here.
    # Supply it at init time:
    #   terraform init -backend-config=backend.hcl
    # Copy backend.hcl.example → backend.hcl and fill in your own bucket name.
    prefix = "gke/terraform"
  }
}
