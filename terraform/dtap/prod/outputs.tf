# Production Environment Outputs

# GKE Cluster outputs
output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "cluster_master_version" {
  description = "Current master version of the GKE cluster"
  value       = google_container_cluster.primary.master_version
}

# Network outputs
output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr" {
  description = "CIDR range of the subnet"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

# Service URLs
output "nginx_ingress_ip" {
  description = "External IP of the NGINX ingress controller"
  value = var.enable_nginx_ingress ? (
    length(helm_release.nginx_ingress) > 0 ? 
      "Run: kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" :
      "NGINX Ingress not deployed"
  ) : "NGINX Ingress disabled"
}

output "argocd_server_url" {
  description = "ArgoCD server URL"
  value = var.enable_argocd ? "https://${var.argocd_server_host}" : "ArgoCD disabled"
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value = var.enable_monitoring ? "https://grafana-prod.example.com" : "Monitoring disabled"
}

output "argo_rollouts_dashboard_url" {
  description = "Argo Rollouts dashboard URL"
  value = var.enable_argo_rollouts ? "https://argo-rollouts-prod.example.com" : "Argo Rollouts disabled"
}

# Connection commands
output "kubectl_connection_command" {
  description = "Command to connect kubectl to the cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.gcp_region} --project ${var.gcp_project_id}"
}

output "argocd_login_command" {
  description = "Command to login to ArgoCD CLI"
  value = var.enable_argocd ? (
    "argocd login ${var.argocd_server_host} --username admin --password <admin-password>"
  ) : "ArgoCD disabled"
}

# Service account outputs
output "gke_node_service_account" {
  description = "Service account used by GKE nodes"
  value       = google_service_account.gke_node_sa.email
}

# Environment information
output "environment" {
  description = "Environment name"
  value       = "production"
}

output "project_id" {
  description = "GCP project ID"
  value       = var.gcp_project_id
}

output "region" {
  description = "GCP region"
  value       = var.gcp_region
}

# Resource tags
output "resource_tags" {
  description = "Tags applied to resources"
  value       = var.environment_tags
}

# Security and compliance
output "private_cluster_enabled" {
  description = "Whether the cluster is private"
  value       = google_container_cluster.primary.private_cluster_config[0].enable_private_nodes
}

output "network_policy_enabled" {
  description = "Whether network policy is enabled"
  value       = google_container_cluster.primary.network_policy[0].enabled
}

output "shielded_nodes_enabled" {
  description = "Whether shielded nodes are enabled"
  value       = google_container_cluster.primary.enable_shielded_nodes
}

output "workload_identity_enabled" {
  description = "Whether workload identity is enabled"
  value = length(google_container_cluster.primary.workload_identity_config) > 0 ? 
    google_container_cluster.primary.workload_identity_config[0].workload_pool : 
    "Disabled"
}

# Monitoring and logging
output "monitoring_service" {
  description = "Monitoring service configured"
  value       = google_container_cluster.primary.monitoring_service
}

output "logging_service" {
  description = "Logging service configured"  
  value       = google_container_cluster.primary.logging_service
}

# Node pool information
output "node_pool_name" {
  description = "Primary node pool name"
  value       = google_container_node_pool.primary_nodes.name
}

output "node_pool_machine_type" {
  description = "Node pool machine type"
  value       = var.node_machine_type
}

output "node_pool_min_count" {
  description = "Minimum number of nodes"
  value       = var.min_node_count
}

output "node_pool_max_count" {
  description = "Maximum number of nodes"
  value       = var.max_node_count
}

# Deployment validation
output "deployment_validation" {
  description = "Post-deployment validation commands"
  value = {
    cluster_status = "kubectl get nodes"
    pod_status     = "kubectl get pods --all-namespaces"
    service_status = "kubectl get services --all-namespaces"
    ingress_status = var.enable_nginx_ingress ? "kubectl get ingress --all-namespaces" : "NGINX Ingress disabled"
    argocd_status  = var.enable_argocd ? "kubectl get pods -n argocd" : "ArgoCD disabled"
    monitoring_status = var.enable_monitoring ? "kubectl get pods -n monitoring" : "Monitoring disabled"
  }
}

# Cost optimization information
output "cost_optimization_info" {
  description = "Information for cost optimization"
  value = {
    preemptible_nodes = "false - Production uses standard nodes for reliability"
    autoscaling_enabled = "true - Nodes scale based on demand"
    resource_requests = "true - All services have resource requests/limits"
    storage_class = "standard-rwo - Production grade storage"
    node_auto_upgrade = "false - Manual upgrades in production for control"
  }
}

# Backup and disaster recovery
output "backup_configuration" {
  description = "Backup and disaster recovery configuration"
  value = {
    cluster_backup = "GKE automatic backups enabled"
    etcd_encryption = "Enabled via GKE"
    multi_zone = "true - Regional cluster for high availability"
    maintenance_window = "Daily at 03:00 UTC"
    binary_authorization = "Enabled for secure deployments"
  }
}