data "google_client_config" "default" {}

# No data source needed - use kubectl config-based authentication
# This relies on the null_resource in the kubernetes_cluster module 
# to configure kubectl properly after cluster creation
