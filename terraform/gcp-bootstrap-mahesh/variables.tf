variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
  default     = "concrete-detection-1-491711"
}
variable "region" {
  default = "us-central1"
}
variable "sa_name" {
  default = "crack-detection-1"
}
variable "dns_zone_name" {
  default = "concretecrackgallery"
}
variable "dns_domain" {
  default = "maheshconcretegallery.online."
}
variable "ip_address" {
  type        = string
  description = "Reserved static IP that the DNS A records point at. Must be supplied (e.g. -var ip_address=<reserved ip> or TF_VAR_ip_address); no default to avoid creating A records pointing at a placeholder."
}
