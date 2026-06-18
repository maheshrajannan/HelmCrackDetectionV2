# Environment: mahesh (project concrete-detection-1-491711)
# Replaces direct use of terraform/gcp-mahesh. All env-specific values live here.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/terraform/gcp-mahesh"
}

inputs = {
  project_id   = "concrete-detection-1-491711"
  region       = "us-central1"
  zone         = "us-central1-a"
  cluster_name = "crack-detection-cluster"

  deletion_protection = false

  # Node pool
  machine_type   = "e2-medium"
  disk_size_gb   = 20
  min_node_count = 3
  max_node_count = 7
}
