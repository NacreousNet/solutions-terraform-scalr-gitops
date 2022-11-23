terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.42.0"
    }
  }
}

provider "google" {
  # Configuration options
  project = var.gcp_project_id
  region  = var.gcp_region

}