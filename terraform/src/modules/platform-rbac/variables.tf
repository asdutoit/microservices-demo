# ==============================================================================
# PLATFORM RBAC MODULE VARIABLES
# ==============================================================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for labeling and organization"
  type        = string
  default     = "online-boutique"
}

# ==============================================================================
# PLATFORM-LEVEL RBAC
# ==============================================================================

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

# ==============================================================================
# TEAM-BASED RBAC
# ==============================================================================

variable "teams" {
  description = "Team configuration with access levels and namespaces"
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
      for team_key, team in var.teams : contains(["developer", "qa", "devops"], team.access_level)
    ])
    error_message = "Team access_level must be one of: developer, qa, devops."
  }

  validation {
    condition = alltrue([
      for team_key, team in var.teams : can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", team.namespace))
    ])
    error_message = "Team namespace must be a valid Kubernetes namespace name (lowercase, alphanumeric, hyphens)."
  }
}

# ==============================================================================
# INTEGRATION SETTINGS
# ==============================================================================

variable "enable_pod_security_policies" {
  description = "Enable Pod Security Policies (deprecated, consider Pod Security Standards)"
  type        = bool
  default     = false
}

variable "enable_network_policies" {
  description = "Enable creation of default network policies for team namespaces"
  type        = bool
  default     = true
}

variable "default_resource_quotas" {
  description = "Default resource quotas to apply to team namespaces"
  type = object({
    enabled = bool
    limits = optional(object({
      cpu_requests    = optional(string, "2")
      cpu_limits      = optional(string, "4") 
      memory_requests = optional(string, "4Gi")
      memory_limits   = optional(string, "8Gi")
      pods           = optional(string, "10")
      services       = optional(string, "5")
      ingresses      = optional(string, "2")
      secrets        = optional(string, "10")
      configmaps     = optional(string, "10")
    }))
  })
  
  default = {
    enabled = false
  }
}

variable "monitoring_config" {
  description = "Configuration for monitoring and observability integrations"
  type = object({
    enable_prometheus_monitoring = optional(bool, true)
    enable_team_dashboards      = optional(bool, true)
    alert_manager_config        = optional(string, "")
  })
  
  default = {
    enable_prometheus_monitoring = true
    enable_team_dashboards      = true
  }
}