# Variables
variable "gcp_project_id_consumer" {
  type        = string
  default     = null
  description = "GCP Project ID for service consumer"
}
variable "gcp_project_id_producer" {
  type        = string
  default     = null
  description = "GCP Project ID for service provider"
}
variable "gcp_project_id" {
  type        = string
  default     = null
  description = "GCP Project ID for provider"
}
variable "gcp_region" {
  type        = string
  default     = "europe-west2"
  description = "GCP Region for provider"
}
variable "gcp_zone_1" {
  type        = string
  default     = "europe-west2-b"
  description = "GCP Zone 1 for provider"
}
variable "prefix" {
  type        = string
  default     = "demo"
  description = "This value is inserted at the beginning of each Google object (alpha-numeric, no special character)"
}
variable "adminSrcAddr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Trusted source network for admin access"
}
variable "cidr_range_mgmt" {
  type        = string
  default     = "10.1.1.0/24"
  description = "IP CIDR range for management VPC network"
}
variable "cidr_range_ext" {
  type        = string
  default     = "10.1.10.0/24"
  description = "IP CIDR range for external VPC network"
}
variable "cidr_range_int" {
  type        = string
  default     = "10.1.20.0/24"
  description = "IP CIDR range for internal VPC network"
}
variable "cidr_range_nat" {
  type        = string
  default     = "10.1.20.0/24"
  description = "IP CIDR range for internal VPC network"
}
variable "owner" {
  type        = string
  default     = null
  description = "This is a tag used for object creation. Example is last name."
}