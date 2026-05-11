terraform {
  backend "gcs" {
    bucket = "crack-detection-terraform-1"  # Replace with your manually created bucket name
    prefix = "gke/terraform"
  }
}
