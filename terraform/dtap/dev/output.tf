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
    
    Check RBAC setup:
    kubectl get serviceaccounts -n ${var.namespace}
    kubectl get roles,rolebindings -n ${var.namespace}
  EOT
}

# Platform RBAC outputs - integrated with platform-rbac module

output "rbac_enabled" {
  description = "Whether platform RBAC is enabled"
  value       = module.dev_kubernetes_cluster.rbac_enabled
}

output "rbac_service_accounts" {
  description = "Service account names for each team"
  value       = module.dev_kubernetes_cluster.rbac_service_accounts
}

output "rbac_summary" {
  description = "Summary of RBAC configuration"
  value       = module.dev_kubernetes_cluster.rbac_summary
}

output "rbac_namespaces" {
  description = "List of namespaces created for teams"
  value       = module.dev_kubernetes_cluster.rbac_namespaces
}

# ============================================================================
# Team-Based RBAC Outputs
# ============================================================================

# Team-Based RBAC outputs - integrated with platform-rbac module

output "team_namespaces" {
  description = "Information about created team namespaces"
  value       = module.dev_kubernetes_cluster.team_namespaces
}

output "team_service_accounts" {
  description = "CI/CD service accounts created for each team"
  value       = module.dev_kubernetes_cluster.team_service_accounts
}

output "platform_roles" {
  description = "Information about platform-level cluster roles"
  value       = module.dev_kubernetes_cluster.platform_roles
}

output "team_roles" {
  description = "Information about team-level cluster roles"
  value       = module.dev_kubernetes_cluster.team_roles
}

output "platform_bindings" {
  description = "Information about platform role bindings"
  value       = module.dev_kubernetes_cluster.platform_bindings
}

output "team_bindings" {
  description = "Information about team role bindings"
  value       = module.dev_kubernetes_cluster.team_bindings
}

output "kubectl_rbac_commands" {
  description = "Useful kubectl commands for RBAC verification"
  value       = module.dev_kubernetes_cluster.kubectl_rbac_commands
}
