# ==============================================================================
# PLATFORM RBAC MODULE OUTPUTS
# ==============================================================================

# ==============================================================================
# CLUSTER-LEVEL ROLE INFORMATION
# ==============================================================================

output "platform_roles" {
  description = "Information about platform-level cluster roles"
  value = {
    platform_admin = {
      name        = kubernetes_cluster_role.platform_admin.metadata[0].name
      uid         = kubernetes_cluster_role.platform_admin.metadata[0].uid
      description = "Full cluster administrator access"
    }
    platform_operator = {
      name        = kubernetes_cluster_role.platform_operator.metadata[0].name
      uid         = kubernetes_cluster_role.platform_operator.metadata[0].uid
      description = "Infrastructure operations without user management"
    }
    platform_viewer = {
      name        = kubernetes_cluster_role.platform_viewer.metadata[0].name
      uid         = kubernetes_cluster_role.platform_viewer.metadata[0].uid
      description = "Read-only cluster access"
    }
  }
}

output "team_roles" {
  description = "Information about team-level cluster roles"
  value = {
    team_developer = {
      name        = kubernetes_cluster_role.team_developer.metadata[0].name
      uid         = kubernetes_cluster_role.team_developer.metadata[0].uid
      description = "Developer access within team namespaces"
    }
    team_qa = {
      name        = kubernetes_cluster_role.team_qa.metadata[0].name
      uid         = kubernetes_cluster_role.team_qa.metadata[0].uid
      description = "QA/Testing access within team namespaces"
    }
    team_devops = {
      name        = kubernetes_cluster_role.team_devops.metadata[0].name
      uid         = kubernetes_cluster_role.team_devops.metadata[0].uid
      description = "DevOps operational access within team namespaces"
    }
  }
}

# ==============================================================================
# TEAM NAMESPACE INFORMATION
# ==============================================================================

output "team_namespaces" {
  description = "Information about created team namespaces"
  value = {
    for team_key, team_config in var.teams : team_key => {
      name           = kubernetes_namespace.team_namespaces[team_key].metadata[0].name
      uid            = kubernetes_namespace.team_namespaces[team_key].metadata[0].uid
      labels         = kubernetes_namespace.team_namespaces[team_key].metadata[0].labels
      access_level   = team_config.access_level
      description    = team_config.description
      team_lead      = team_config.lead_email
      member_count   = length(team_config.members)
    }
  }
}

output "team_service_accounts" {
  description = "CI/CD service accounts created for each team"
  value = {
    for team_key, team_config in var.teams : team_key => {
      name      = kubernetes_service_account.cicd_deployer[team_key].metadata[0].name
      namespace = kubernetes_service_account.cicd_deployer[team_key].metadata[0].namespace
      uid       = kubernetes_service_account.cicd_deployer[team_key].metadata[0].uid
      purpose   = "CI/CD automation for ${team_key} team"
    }
  }
}

# ==============================================================================
# ROLE BINDING INFORMATION
# ==============================================================================

output "platform_bindings" {
  description = "Information about platform role bindings"
  value = {
    admins = length(var.platform_admins) > 0 ? {
      name    = kubernetes_cluster_role_binding.platform_admins[0].metadata[0].name
      uid     = kubernetes_cluster_role_binding.platform_admins[0].metadata[0].uid
      members = var.platform_admins
    } : null

    operators = length(var.platform_operators) > 0 ? {
      name    = kubernetes_cluster_role_binding.platform_operators[0].metadata[0].name
      uid     = kubernetes_cluster_role_binding.platform_operators[0].metadata[0].uid
      members = var.platform_operators
    } : null

    viewers = length(var.platform_viewers) > 0 ? {
      name    = kubernetes_cluster_role_binding.platform_viewers[0].metadata[0].name
      uid     = kubernetes_cluster_role_binding.platform_viewers[0].metadata[0].uid
      members = var.platform_viewers
    } : null
  }
}

output "team_bindings" {
  description = "Information about team role bindings"
  value = {
    for team_key, team_config in var.teams : team_key => {
      namespace_binding = {
        name         = kubernetes_role_binding.team_namespace_access[team_key].metadata[0].name
        namespace    = kubernetes_role_binding.team_namespace_access[team_key].metadata[0].namespace
        uid          = kubernetes_role_binding.team_namespace_access[team_key].metadata[0].uid
        cluster_role = "team-${team_config.access_level}"
        members      = concat([team_config.lead_email], team_config.members)
      }
      
      cicd_binding = {
        name           = kubernetes_role_binding.cicd_deployer_binding[team_key].metadata[0].name
        namespace      = kubernetes_role_binding.cicd_deployer_binding[team_key].metadata[0].namespace
        uid            = kubernetes_role_binding.cicd_deployer_binding[team_key].metadata[0].uid
        service_account = "${team_key}-cicd-deployer"
      }
    }
  }
}

# ==============================================================================
# RBAC SUMMARY AND UTILITIES
# ==============================================================================

output "rbac_summary" {
  description = "High-level summary of RBAC configuration"
  value = {
    environment    = var.environment
    project_name   = var.project_name
    
    platform_users = {
      admin_count    = length(var.platform_admins)
      operator_count = length(var.platform_operators)
      viewer_count   = length(var.platform_viewers)
      total_count    = length(var.platform_admins) + length(var.platform_operators) + length(var.platform_viewers)
    }
    
    teams = {
      total_teams     = length(var.teams)
      total_members   = sum([for team in var.teams : length(team.members) + 1])  # +1 for lead
      namespaces      = [for team in var.teams : team.namespace]
      access_levels   = distinct([for team in var.teams : team.access_level])
    }
    
    automation = {
      cicd_accounts  = length(var.teams)
      total_bindings = length(var.teams) * 2  # namespace + cicd bindings per team
    }
  }
}

output "kubectl_commands" {
  description = "Useful kubectl commands for RBAC verification"
  value = {
    # Platform role verification
    list_platform_roles = "kubectl get clusterroles -l rbac.platform/role-type=platform"
    list_team_roles      = "kubectl get clusterroles -l rbac.platform/role-type=team"
    
    # Binding verification
    list_platform_bindings = "kubectl get clusterrolebindings -l rbac.platform/managed-by=terraform"
    list_team_bindings      = "kubectl get rolebindings --all-namespaces -l rbac.platform/managed-by=terraform"
    
    # Namespace verification
    list_team_namespaces    = "kubectl get namespaces -l rbac.platform/managed-by=terraform"
    
    # Service account verification
    list_cicd_accounts      = "kubectl get serviceaccounts --all-namespaces -l rbac.platform/purpose=cicd-automation"
    
    # Permission testing (replace USER_EMAIL)
    test_permissions = "kubectl auth can-i --list --as=USER_EMAIL"
    test_namespace_access = "kubectl auth can-i get pods --namespace=NAMESPACE --as=USER_EMAIL"
  }
}

# Export namespace list for use by application deployments
output "application_namespaces" {
  description = "List of namespaces where applications can be deployed"
  value = [for team in var.teams : team.namespace]
}