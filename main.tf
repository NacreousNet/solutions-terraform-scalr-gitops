
/*

# Create the project
resource "google_project" "project" {
  name       = var.gcp_project_id
  project_id = var.gcp_project_id
  auto_create_network = false
}

*/

# Use `gcloud` to enable:
# - serviceusage.googleapis.com
# - cloudresourcemanager.googleapis.com
#resource "null_resource" "enable_service_usage_api" {
 # provisioner "local-exec" {
    #command = "gcloud services enable  compute.googleapis.com --project ${var.gcp_project_id}"
  #}

#serviceusage.googleapis.com cloudresourcemanager.googleapis.com

  #depends_on = [google_project.project]
 
 /*
  depends_on = [
    google_project.project
  ]

  */
#}