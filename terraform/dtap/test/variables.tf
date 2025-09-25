variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID to apply this config to"
  default     = "company-test-project"  # Placeholder project ID
}

variable "name" {
  type        = string
  description = "Name given to the new GKE cluster"
  default     = "online-boutique-test"
}

variable "region" {
  type        = string
  description = "Region of the new GKE cluster"
  default     = "europe-west4"
}

variable "namespace" {
  type        = string
  description = "Kubernetes Namespace in which the Online Boutique resources are to be deployed"
  default     = "test"
}

variable "filepath_manifest" {
  type        = string
  description = "Path to Online Boutique's Kubernetes resources, written using Kustomize"
  default     = "../kustomize/"
}

variable "memorystore" {
  type        = bool
  description = "If true, Online Boutique's in-cluster Redis cache will be replaced with a Google Cloud Memorystore Redis cache"
  default     = false
}

variable "enable_rbac_cluster_access" {
  description = "Enable cluster-level RBAC access for frontend service (for metrics and health checks)"
  type        = bool
  default     = false
}

# ==============================================================================
# PLATFORM RBAC INTEGRATION
# ==============================================================================

variable "enable_platform_rbac" {
  description = "Enable platform-level RBAC management"
  type        = bool
  default     = true
}

variable "platform_admins" {
  description = "List of users with full cluster admin access"
  type        = list(string)
  default     = ["admin@company.com"]  # Replace with actual admin emails
}

variable "platform_operators" {
  description = "List of users with infrastructure operations access (no user management)"
  type        = list(string)
  default     = ["devops@company.com"]  # Replace with actual operator emails
}

variable "platform_viewers" {
  description = "List of users with read-only cluster access"
  type        = list(string)
  default     = ["viewer@company.com"]  # Replace with actual viewer emails
}

variable "rbac_teams" {
  description = "Team configuration with access levels and namespaces for RBAC"
  type = map(object({
    namespace    = string       # Kubernetes namespace for the team
    access_level = string       # developer, qa, devops (maps to ClusterRole)
    description  = string       # Team description
    lead_email   = string       # Team lead email (primary contact)
    members      = list(string) # List of team member emails
    contacts     = list(string) # Additional contact emails for notifications
    cost_center  = optional(string, "")
    
    # Optional cross-namespace access
    additional_namespace_access = optional(list(string), [])
  }))
  
  default = {
    testers = {
      namespace    = "test"
      access_level = "qa"
      description  = "QA testing team with full access to test namespace"
      lead_email   = "qa-lead@company.com"
      members      = ["tester1@company.com", "tester2@company.com"]
      contacts     = ["qa-notifications@company.com"]
      cost_center  = "engineering-test"
    }
  }
}

variable "domain_name" {
  description = "Domain name for ingress hosts (leave empty to use LoadBalancer IPs)"
  type        = string
  default     = ""  # Uses LoadBalancer IPs by default
}

variable "argocd_admin_password" {
  description = "Admin password for ArgoCD (leave empty for auto-generated)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pod_readiness_timeout" {
  description = "Timeout in seconds to wait for pods to be ready. Increase for GKE Autopilot or CI/CD environments."
  type        = number
  default     = 1200  # Higher default for test environment
}

variable "skip_pod_wait" {
  description = "Skip waiting for pods to be ready. Set to true in CI/CD environments to avoid timeouts."
  type        = bool
  default     = false
}
