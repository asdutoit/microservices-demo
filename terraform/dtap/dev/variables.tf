variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID to apply this config to"
}

variable "name" {
  type        = string
  description = "Name given to the new GKE cluster"
  default     = "online-boutique"
}

variable "region" {
  type        = string
  description = "Region of the new GKE cluster"
  default     = "europe-west4"
}

variable "namespace" {
  type        = string
  description = "Kubernetes Namespace in which the Online Boutique resources are to be deployed"
  default     = "default"
}

variable "filepath_manifest" {
  type        = string
  description = "Path to Online Boutique's Kubernetes resources, written using Kustomize"
  default     = "../../../kustomize/"
}

variable "memorystore" {
  type        = bool
  description = "If true, Online Boutique's in-cluster Redis cache will be replaced with a Google Cloud Memorystore Redis cache"
  default     = false
}

variable "enable_rbac_cluster_access" {
  type        = bool
  description = "Enable cluster-level RBAC access for services that need metrics and health checks"
  default     = false
}

variable "domain_name" {
  type        = string
  description = "Domain name for ingress resources (ArgoCD, Argo Rollouts, etc.)"
  default     = ""
}

variable "argocd_admin_password" {
  type        = string
  description = "Admin password for ArgoCD (leave empty for default 'admin123')"
  default     = ""
  sensitive   = true
}

# ==============================================================================
# PLATFORM RBAC CONFIGURATION
# ==============================================================================

variable "enable_platform_rbac" {
  description = "Enable platform-level RBAC management"
  type        = bool
  default     = true
}

variable "ci_cd_mode" {
  description = <<-EOT
    Set to true when running in CI/CD environments to disable complex features.
    When enabled, this will:
    - Disable platform RBAC (to avoid kubectl authentication issues)
    - Skip application deployment (focus on infrastructure testing)
    - Simplify deployment for automated testing
  EOT
  type        = bool
  default     = false
}

variable "skip_app_deployment" {
  description = "Skip application deployment (useful for infrastructure-only testing)"
  type        = bool
  default     = false
}

variable "platform_admins" {
  description = "List of users with full cluster admin access"
  type        = list(string)
  default     = []
}

variable "platform_operators" {
  description = "List of users with infrastructure operations access"
  type        = list(string)
  default     = []
}

variable "platform_viewers" {
  description = "List of users with read-only cluster access"
  type        = list(string)
  default     = []
}

variable "rbac_teams" {
  description = "Team configuration with access levels and namespaces for RBAC"
  type = map(object({
    namespace    = string       # Kubernetes namespace for the team
    access_level = string       # developer, qa, devops
    description  = string       # Team description
    lead_email   = string       # Team lead email
    members      = list(string) # List of team member emails
    contacts     = list(string) # Additional contact emails
    cost_center  = optional(string, "")

    # Optional cross-namespace access
    additional_namespace_access = optional(list(string), [])
  }))

  default = {
    # Example team configuration - customize as needed
    developers = {
      namespace    = "development"
      access_level = "developer"
      description  = "Development team with full access to development namespace"
      lead_email   = "dev-lead@example.com"
      members      = []
      contacts     = ["dev-team@example.com"]
      cost_center  = "engineering"
    }
  }
}

variable "pod_readiness_timeout" {
  description = "Timeout in seconds to wait for pods to be ready. Increase for GKE Autopilot or CI/CD environments."
  type        = number
  default     = 900
}

variable "skip_pod_wait" {
  description = "Skip waiting for pods to be ready. Set to true in CI/CD environments to avoid timeouts."
  type        = bool
  default     = false
}
