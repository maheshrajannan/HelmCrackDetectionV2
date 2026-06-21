resource "google_container_node_pool" "primary" {
  name     = "primary-node-pool"
  cluster  = google_container_cluster.crack_detection.name
  location = var.zone

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
