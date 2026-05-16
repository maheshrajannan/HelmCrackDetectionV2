provider "google" {
  project = "concrete-detection-5"
  region  = "us-central1"
}

terraform {
  backend "gcs" {
    bucket = "concrete-detection-terraform-state"  # Replace with your GCS bucket name
    prefix = "gke-cluster/terraform/state"         # Folder structure in GCS bucket
  }
}

resource "google_container_cluster" "crack-detection-cluster" {
  name     = "crack-detection-cluster"
  location = "us-central1-a"
  initial_node_count = 2
  deletion_protection = var.deletion_protection
  network            = "default"
  subnetwork         = "default"

  release_channel {
    channel = "REGULAR"
  }
}

variable "deletion_protection" {
  description = "Enable or disable deletion protection for the cluster"
  type        = bool
  default     = false
}

data "google_container_cluster" "crack-detection-cluster" {
  name     = google_container_cluster.crack-detection-cluster.name
  location = google_container_cluster.crack-detection-cluster.location
}

# Output for the cluster name
output "cluster_name" {
  value = google_container_cluster.crack-detection-cluster.name
}

# Output for kubectl configuration
output "kubectl_config" {
  value = <<EOT
  gcloud container clusters get-credentials ${google_container_cluster.crack-detection-cluster.name} \
    --region ${google_container_cluster.crack-detection-cluster.location} \
    --project "concrete-detection-5"
  EOT
  sensitive = true
}
