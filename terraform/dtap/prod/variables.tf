# Production Environment Variables

variable "gcp_project_id" {
  description = "The GCP project ID for production environment"
  type        = string
  default     = "company-prod-project"  # Placeholder - replace with actual prod project ID
}

variable "gcp_region" {
  description = "GCP region for production resources"
  type        = string
  default     = "europe-west4"
}

variable "gcp_zone" {
  description = "GCP zone for production resources"
  type        = string
  default     = "europe-west4-a"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "online-boutique-prod"
}

variable "kubernetes_version" {
  description = "The Kubernetes version for the GKE cluster"
  type        = string
  default     = "1.27.8-gke.1067004"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.30.0.0/16"  # Different range for production
}

# Production node configuration - higher capacity
variable "node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-4"  # Larger instances for production
}

variable "node_count" {
  description = "Initial number of nodes in the node pool"
  type        = number
  default     = 3  # Higher baseline for production
}

variable "min_node_count" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "max_node_count" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 10  # Higher scale capacity for production
}

# Platform services configuration
variable "enable_argocd" {
  description = "Enable ArgoCD deployment"
  type        = bool
  default     = true
}

variable "enable_argo_rollouts" {
  description = "Enable Argo Rollouts deployment"
  type        = bool
  default     = true
}

variable "enable_nginx_ingress" {
  description = "Enable NGINX Ingress Controller deployment"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Enable Cert Manager deployment"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable centralized logging (ELK/Fluentd)"
  type        = bool
  default     = true
}

# ArgoCD configuration
variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.46.8"
}

variable "argocd_admin_password" {
  description = "ArgoCD admin password (use bcrypt hash)"
  type        = string
  sensitive   = true
  default     = "$2a$12$Rv3ZEP71qvwJZgWHhUtHleOFO4Lsz7vBbq8e5J5F8QTu.qkYO5Rqe"  # Default: admin
}

variable "argocd_server_host" {
  description = "ArgoCD server hostname"
  type        = string
  default     = "argocd-prod.example.com"
}

# NGINX Ingress configuration
variable "nginx_ingress_chart_version" {
  description = "NGINX Ingress Controller Helm chart version"
  type        = string
  default     = "4.8.3"
}

# Cert Manager configuration
variable "cert_manager_chart_version" {
  description = "Cert Manager Helm chart version"
  type        = string
  default     = "1.13.2"
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
  default     = "admin@example.com"
}

# Monitoring configuration
variable "prometheus_chart_version" {
  description = "Prometheus Helm chart version"
  type        = string
  default     = "25.4.0"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "production-secure-password"
}

# Application configuration
variable "online_boutique_image_tag" {
  description = "Image tag for Online Boutique application"
  type        = string
  default     = "v0.8.0"
}

variable "online_boutique_namespace" {
  description = "Kubernetes namespace for Online Boutique"
  type        = string
  default     = "default"
}

# Security configuration
variable "enable_pod_security_policy" {
  description = "Enable Pod Security Policy"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable Network Policies"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization"
  type        = bool
  default     = true
}

# Backup and disaster recovery
variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}

# Resource limits and requests
variable "resource_limits_enabled" {
  description = "Enable resource limits and requests"
  type        = bool
  default     = true
}

# Environment-specific tags
variable "environment_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Team        = "platform"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
    Criticality = "high"
  }
}