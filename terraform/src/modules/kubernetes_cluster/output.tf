output "cluster_location" {
  description = "Location of the cluster"
  value       = resource.google_container_cluster.my_cluster.location
}

output "cluster_name" {
  description = "Name of the cluster"
  value       = resource.google_container_cluster.my_cluster.name
}

output "kubectl_context_command" {
  description = "Command to set kubectl context for this cluster"
  value       = "gcloud container clusters get-credentials ${resource.google_container_cluster.my_cluster.name} --region=${resource.google_container_cluster.my_cluster.location} --project=${var.gcp_project_id}"
}

output "kubectl_config_info" {
  description = "Information about the kubectl configuration"
  value = {
    cluster_name   = resource.google_container_cluster.my_cluster.name
    cluster_region = resource.google_container_cluster.my_cluster.location
    project_id     = var.gcp_project_id
    context_name   = "gke_${var.gcp_project_id}_${resource.google_container_cluster.my_cluster.location}_${resource.google_container_cluster.my_cluster.name}"
  }
}
