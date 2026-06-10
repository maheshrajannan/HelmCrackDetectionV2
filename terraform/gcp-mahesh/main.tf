provider "google" {
  project = var.project_id
  region  = var.region
}

# GKE Cluster (NO default node pool)
resource "google_container_cluster" "crack_detection" {
  name     = var.cluster_name
  location = var.zone

  # Important: remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network
  subnetwork = var.subnetwork

  deletion_protection = var.deletion_protection

  release_channel {
    channel = "REGULAR"
  }
}

# Outputs
output "cluster_name" {
  value = google_container_cluster.crack_detection.name
}

output "kubectl_config" {
  value     = <<EOT
gcloud container clusters get-credentials ${google_container_cluster.crack_detection.name} \
  --zone ${var.zone} \
  --project ${var.project_id}
EOT
  sensitive = true
}
