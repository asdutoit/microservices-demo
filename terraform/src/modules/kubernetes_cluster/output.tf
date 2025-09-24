output "cluster_location" {
  description = "Location of the cluster"
  value       = resource.google_container_cluster.my_cluster.location
}

output "cluster_name" {
  description = "Name of the cluster"
  value       = resource.google_container_cluster.my_cluster.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = resource.google_container_cluster.my_cluster.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = resource.google_container_cluster.my_cluster.master_auth.0.cluster_ca_certificate
  sensitive   = true
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

# Platform RBAC outputs - integrated with platform-rbac module

output "rbac_enabled" {
  description = "Whether platform RBAC is enabled"
  value       = var.enable_platform_rbac
}

output "rbac_service_accounts" {
  description = "Service account names for each team"
  value       = var.enable_platform_rbac ? module.platform_rbac[0].team_service_accounts : {}
}

output "rbac_summary" {
  description = "Summary of RBAC configuration"
  value       = var.enable_platform_rbac ? module.platform_rbac[0].rbac_summary : null
}

output "rbac_namespaces" {
  description = "List of namespaces created for teams"
  value       = var.enable_platform_rbac ? module.platform_rbac[0].application_namespaces : []
}

output "cluster_master_version" {
  description = "Version of Kubernetes master"
  value       = google_container_cluster.my_cluster.master_version
}

output "cluster_node_version" {
  description = "Version of Kubernetes nodes"
  value       = google_container_cluster.my_cluster.node_version
}

# ============================================================================
# Autopilot Cluster Information
# ============================================================================
# Note: Autopilot clusters don't have user-managed node pools or service accounts
# All node management is handled automatically by Google

# ============================================================================
# Team-Based RBAC Outputs
# ============================================================================

# Team-Based RBAC outputs - integrated with platform-rbac module

output "team_namespaces" {
  description = "Information about created team namespaces"
  value       = var.enable_platform_rbac ? module.platform_rbac[0].team_namespaces : {}
}

output "team_service_accounts" {
  description = "CI/CD service accounts created for each team"
  value       = var.enable_platform_rbac ? module.platform_rbac[0].team_service_accounts : {}
}

output "platform_roles" {
  description = "Information about platform-level cluster roles"
  value       = var.enable_platform_rbac ? module.platform_rbac[0].platform_roles : {}
}

output "team_roles" {
  description = "Information about team-level cluster roles"
  value       = var.enable_platform_rbac ? module.platform_rbac[0].team_roles : {}
}

output "platform_bindings" {
  description = "Information about platform role bindings"
  value       = var.enable_platform_rbac ? module.platform_rbac[0].platform_bindings : {}
}

output "team_bindings" {
  description = "Information about team role bindings"
  value       = var.enable_platform_rbac ? module.platform_rbac[0].team_bindings : {}
}

output "kubectl_rbac_commands" {
  description = "Useful kubectl commands for RBAC verification"
  value       = var.enable_platform_rbac ? module.platform_rbac[0].kubectl_commands : {}
}

# ============================================================================
# Connection Information
# ============================================================================

output "connect_instructions" {
  description = "Instructions for connecting to the cluster"
  value       = <<-EOT
    To connect to your GKE cluster, run:
        
    gcloud container clusters get-credentials ${google_container_cluster.my_cluster.name} --region=${google_container_cluster.my_cluster.location} --project=${var.gcp_project_id}
        
    Then verify the connection:
    kubectl get nodes
    kubectl get pods -A
        
    Check RBAC setup:
    kubectl get serviceaccounts -n ${var.namespace}
    kubectl get roles,rolebindings -n ${var.namespace}
    
    Check team RBAC (if enabled):
    kubectl get clusterroles -l app.kubernetes.io/component=rbac
    kubectl get clusterrolebindings -l app.kubernetes.io/component=rbac
  EOT
}
