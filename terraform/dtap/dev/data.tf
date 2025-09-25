data "google_client_config" "default" {}

# Data source to get cluster information for provider configuration
# This will be used when the cluster exists for proper authentication
data "google_container_cluster" "cluster" {
  name     = "online-boutique"  # Use the actual cluster name from state. TODO: Replace with var
  location = var.region
  project  = var.gcp_project_id
}
