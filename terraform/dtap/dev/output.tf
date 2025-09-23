output "cluster_location" {
  description = "Location of the cluster"
  value       = module.dev_kubernetes_cluster.cluster_location
}

output "cluster_name" {
  description = "Name of the cluster"
  value       = module.dev_kubernetes_cluster.cluster_name
}

output "kubectl_context_command" {
  description = "Command to set kubectl context for this cluster"
  value       = module.dev_kubernetes_cluster.kubectl_context_command
}

output "kubectl_config_info" {
  description = "Information about the kubectl configuration"
  value       = module.dev_kubernetes_cluster.kubectl_config_info
}

output "connect_instructions" {
  description = "Instructions to connect to the GKE cluster"
  value       = <<-EOT
    To connect to your GKE cluster, run:
    
    ${module.dev_kubernetes_cluster.kubectl_context_command}
    
    Then verify the connection:
    kubectl get nodes
    kubectl get pods -A
  EOT
}
