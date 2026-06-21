provider "google" {
  project = "concrete-detection-1-491711"
  region  = "us-central1"
}

# GKE Cluster (NO default node pool)
resource "google_container_cluster" "crack_detection" {
  name     = var.cluster_name
  location = "us-central1-a"

  # Important: remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = "default"
  subnetwork = "default"

  deletion_protection = var.deletion_protection

  release_channel {
    channel = "REGULAR"
  }
}

# Variables
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "crack-detection-cluster"
}

variable "deletion_protection" {
  description = "Enable or disable deletion protection for the cluster"
  type        = bool
  default     = false
}

# Outputs
output "cluster_name" {
  value = google_container_cluster.crack_detection.name
}

output "kubectl_config" {
  value = <<EOT
gcloud container clusters get-credentials ${google_container_cluster.crack_detection.name} \
  --zone us-central1-a \
  --project concrete-detection-1-491711
EOT
  sensitive = true
}
