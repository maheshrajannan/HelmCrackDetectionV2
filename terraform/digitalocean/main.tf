terraform {
  backend "s3" {
    endpoints = {
        s3  =  "https://nyc3.digitaloceanspaces.com"
    }
    bucket     = "terraform-crack-detection"
    key        = "DO-cluster/terraform.tfstate"
    access_key = var.DO_bucket_access_key
    region     = "us-east-1"
    secret_key = var.DO_bucket_secret_key
    skip_credentials_validation = true
    skip_requesting_account_id = true
  }

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34.0"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

variable "DO_bucket_access_key" {
  description = "DO Bucket Access Key"
  type        = string
  sensitive   = true
}

variable "DO_bucket_secret_key" {
  description = "DO Bucket Secret Key"
  type        = string
  sensitive   = true
}

variable "digitalocean_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  default     = "crack-detection-cluster"
}

variable "region" {
  description = "DigitalOcean region"
  default     = "nyc3"
}

variable "node_count" {
  description = "Number of nodes in the Kubernetes cluster"
  default     = 2
}

variable "node_size" {
  description = "Node size for the Kubernetes cluster"
  default     = "s-1vcpu-2gb"
}

# Fetch available Kubernetes versions in the selected region
data "digitalocean_kubernetes_versions" "latest" {}

# Create Kubernetes Cluster
resource "digitalocean_kubernetes_cluster" "crack-detection-cluster" {
  name    = var.cluster_name
  region  = var.region
  version = data.digitalocean_kubernetes_versions.latest.valid_versions[0]

  node_pool {
    name       = "default-pool"
    size       = var.node_size
    node_count = var.node_count
  }
}

# Output for Kubernetes Config
output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.crack-detection-cluster.kube_config[0].raw_config
  sensitive = true
}

# Outputs for Cluster Details
output "cluster_endpoint" {
  value = digitalocean_kubernetes_cluster.crack-detection-cluster.endpoint
}

output "cluster_id" {
  value = digitalocean_kubernetes_cluster.crack-detection-cluster.id
}