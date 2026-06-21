variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "concrete-detection-1-491711" # default matches current value; override via Terragrunt inputs
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for the cluster and node pool"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "crack-detection-cluster"
}

variable "network" {
  description = "VPC network"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "VPC subnetwork"
  type        = string
  default     = "default"
}

variable "deletion_protection" {
  description = "Enable or disable deletion protection for the cluster"
  type        = bool
  default     = false
}

variable "machine_type" {
  description = "Node pool machine type"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Node disk size in GB"
  type        = number
  default     = 20
}

variable "min_node_count" {
  description = "Node pool autoscaling minimum"
  type        = number
  default     = 3
}

variable "max_node_count" {
  description = "Node pool autoscaling maximum"
  type        = number
  default     = 7
}
