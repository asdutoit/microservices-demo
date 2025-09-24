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
  default     = "us-central1"
}

# Node pool variables not needed for Autopilot clusters
# Autopilot manages nodes automatically

variable "namespace" {
  type        = string
  description = "Kubernetes Namespace in which the Online Boutique resources are to be deployed"
  default     = "default"
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


variable "vpc_name" {
  description = "The name of the VPC network to deploy the GKE cluster into"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnetwork to deploy the GKE cluster into"
  type        = string
}

variable "deletion_protection" {
  description = "If true, the GKE cluster will have deletion protection enabled"
  type        = bool
  default     = true
}

variable "ip_allocation_policy" {
  description = "Configuration block for IP allocation policy"
  type = object({
    cluster_secondary_range_name  = string
    services_secondary_range_name = string
  })
  default = null
}

variable "apis_dependency" {
  description = "Dependency on API enablement"
  type        = any
  default     = null
}

variable "enable_rbac_cluster_access" {
  description = "Enable cluster-level RBAC access for frontend service (for metrics and health checks)"
  type        = bool
  default     = false
}

# ============================================================================
# Team-based RBAC Configuration
# ============================================================================

variable "teams" {
  description = "Configuration for organizational teams and their access levels"
  type = map(object({
    members     = list(string) # Google accounts, service accounts, or groups
    namespaces  = list(string) # Namespaces the team can access ("*" for all)
    permissions = string       # Permission level: viewer, editor, admin, platform
    description = optional(string, "")
  }))
  default = {}
}

variable "enable_team_rbac" {
  description = "Enable team-based RBAC roles and bindings"
  type        = bool
  default     = true
}

variable "team_role_prefix" {
  description = "Prefix for team role names"
  type        = string
  default     = "team"
}

variable "additional_team_permissions" {
  description = "Additional permissions for specific teams"
  type = map(list(object({
    api_groups     = list(string)
    resources      = list(string)
    verbs          = list(string)
    resource_names = optional(list(string), [])
  })))
  default = {}
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
  default     = []
}

variable "platform_operators" {
  description = "List of users with infrastructure operations access (no user management)"
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
    access_level = string       # developer, qa, devops (maps to ClusterRole)
    description  = string       # Team description
    lead_email   = string       # Team lead email (primary contact)
    members      = list(string) # List of team member emails
    contacts     = list(string) # Additional contact emails for notifications
    cost_center  = optional(string, "")
    
    # Optional cross-namespace access
    additional_namespace_access = optional(list(string), [])
  }))
  
  default = {}

  validation {
    condition = alltrue([
      for team_key, team in var.rbac_teams : contains(["developer", "qa", "devops"], team.access_level)
    ])
    error_message = "Team access_level must be one of: developer, qa, devops."
  }

  validation {
    condition = alltrue([
      for team_key, team in var.rbac_teams : can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", team.namespace))
    ])
    error_message = "Team namespace must be a valid Kubernetes namespace name (lowercase, alphanumeric, hyphens)."
  }
}

variable "platform_project_name" {
  description = "Project name for RBAC labeling and organization"
  type        = string
  default     = "online-boutique"
}

variable "rbac_environment" {
  description = "Environment name for RBAC (dev, staging, prod)"
  type        = string
  default     = "dev"
}
