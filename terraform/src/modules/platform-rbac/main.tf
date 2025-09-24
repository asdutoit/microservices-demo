# ==============================================================================
# PLATFORM RBAC MODULE
# ==============================================================================
# This module manages platform-level RBAC for teams and operational roles
# Separate from application-level RBAC which is managed in app manifests

# ==============================================================================
# CLUSTER-LEVEL ROLES
# ==============================================================================

# Platform Admin - Full cluster access for platform engineering team
resource "kubernetes_cluster_role" "platform_admin" {
  metadata {
    name = "platform-admin"
    labels = {
      "rbac.platform/role-type"    = "platform"
      "rbac.platform/scope"       = "cluster"
      "rbac.platform/managed-by"  = "terraform"
    }
  }

  # Full cluster admin capabilities
  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

# Platform Operator - Infrastructure operations without user management
resource "kubernetes_cluster_role" "platform_operator" {
  metadata {
    name = "platform-operator"
    labels = {
      "rbac.platform/role-type"   = "platform"
      "rbac.platform/scope"      = "cluster"
      "rbac.platform/managed-by" = "terraform"
    }
  }

  # Node management
  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/status", "nodes/metrics"]
    verbs      = ["get", "list", "watch", "patch", "update"]
  }

  # Pod management for operations
  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "pods/status", "pods/exec"]
    verbs      = ["get", "list", "watch", "create", "delete", "patch", "update"]
  }

  # Deployment and workload management
  rule {
    api_groups = ["apps", "extensions"]
    resources  = ["deployments", "replicasets", "daemonsets", "statefulsets"]
    verbs      = ["get", "list", "watch", "create", "delete", "patch", "update"]
  }

  # Service and networking
  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "persistentvolumes", "persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "create", "delete", "patch", "update"]
  }
  
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies", "ingressclasses"]
    verbs      = ["get", "list", "watch", "create", "delete", "patch", "update"]
  }

  # ConfigMaps and Secrets (operational)
  rule {
    api_groups = [""]
    resources  = ["configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "delete", "patch", "update"]
  }

  # Events and metrics
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch"]
  }
  
  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["nodes", "pods", "containers"]
    verbs      = ["get", "list"]
  }
}

# Platform Viewer - Read-only access to cluster resources
resource "kubernetes_cluster_role" "platform_viewer" {
  metadata {
    name = "platform-viewer"
    labels = {
      "rbac.platform/role-type"   = "platform"
      "rbac.platform/scope"      = "cluster"
      "rbac.platform/managed-by" = "terraform"
    }
  }

  # Read-only access to most resources
  rule {
    api_groups = ["", "apps", "extensions", "networking.k8s.io", "storage.k8s.io"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["nodes", "pods", "containers"]
    verbs      = ["get", "list"]
  }
}

# ==============================================================================
# TEAM-BASED NAMESPACE ROLES
# ==============================================================================

# Developer Role - Edit access within assigned namespaces
resource "kubernetes_cluster_role" "team_developer" {
  metadata {
    name = "team-developer"
    labels = {
      "rbac.platform/role-type"   = "team"
      "rbac.platform/scope"      = "namespace"
      "rbac.platform/managed-by" = "terraform"
    }
  }

  # Application workloads
  rule {
    api_groups = ["", "apps", "extensions"]
    resources = [
      "deployments", "replicasets", "statefulsets", "daemonsets",
      "pods", "pods/log", "pods/status",
      "services", "endpoints",
      "configmaps", "secrets",
      "persistentvolumeclaims"
    ]
    verbs = ["get", "list", "watch", "create", "delete", "patch", "update"]
  }

  # Networking within namespace
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch", "create", "delete", "patch", "update"]
  }

  # Events and basic metrics
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch", "create"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "containers"]
    verbs      = ["get", "list"]
  }

  # Job and CronJob management
  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "delete", "patch", "update"]
  }
}

# QA/Test Role - Limited access focused on testing
resource "kubernetes_cluster_role" "team_qa" {
  metadata {
    name = "team-qa"
    labels = {
      "rbac.platform/role-type"   = "team"
      "rbac.platform/scope"      = "namespace"
      "rbac.platform/managed-by" = "terraform"
    }
  }

  # Read access to deployments and services
  rule {
    api_groups = ["", "apps", "extensions"]
    resources = [
      "deployments", "replicasets", "statefulsets",
      "pods", "pods/log", "pods/status",
      "services", "endpoints",
      "configmaps"
    ]
    verbs = ["get", "list", "watch"]
  }

  # Can create test jobs and view results
  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "delete"]
  }

  # Can create test pods for debugging
  rule {
    api_groups = [""]
    resources  = ["pods", "pods/exec"]
    verbs      = ["create", "delete", "get", "list", "watch"]
  }

  # Events and metrics
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "containers"]
    verbs      = ["get", "list"]
  }
}

# DevOps Role - Operational access with deployment capabilities
resource "kubernetes_cluster_role" "team_devops" {
  metadata {
    name = "team-devops"
    labels = {
      "rbac.platform/role-type"   = "team"
      "rbac.platform/scope"      = "namespace"
      "rbac.platform/managed-by" = "terraform"
    }
  }

  # Full namespace resource management
  rule {
    api_groups = ["", "apps", "extensions", "networking.k8s.io", "batch"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  # Can manage service accounts and role bindings within namespace
  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["rolebindings"]
    verbs      = ["get", "list", "watch", "create", "delete", "patch", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["get", "list", "watch", "create", "delete", "patch", "update", "impersonate"]
  }

  # Metrics and monitoring
  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["nodes", "pods", "containers"]
    verbs      = ["get", "list"]
  }

  # Storage management
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "list", "watch"]
  }
}

# ==============================================================================
# TEAM NAMESPACE MANAGEMENT
# ==============================================================================

# Create namespaces for each team
resource "kubernetes_namespace" "team_namespaces" {
  for_each = var.teams

  metadata {
    name = each.value.namespace
    labels = {
      "team"                         = each.key
      "rbac.platform/managed-by"    = "terraform"
      "rbac.platform/team-access"   = each.value.access_level
      "environment"                  = var.environment
    }
    annotations = {
      "description"    = each.value.description
      "contact"        = join(",", each.value.contacts)
      "cost-center"    = try(each.value.cost_center, "")
      "project"        = var.project_name
    }
  }
}

# ==============================================================================
# TEAM ROLE BINDINGS
# ==============================================================================

# Bind team members to their appropriate roles in their namespaces
resource "kubernetes_role_binding" "team_namespace_access" {
  for_each = var.teams

  metadata {
    name      = "${each.key}-team-access"
    namespace = kubernetes_namespace.team_namespaces[each.key].metadata[0].name
    labels = {
      "team"                        = each.key
      "rbac.platform/managed-by"   = "terraform"
      "rbac.platform/binding-type" = "team-namespace"
    }
    annotations = {
      "description" = "${each.value.description} - Team access to ${each.value.namespace} namespace"
    }
  }

  subject {
    kind      = "User"
    name      = each.value.lead_email
    api_group = "rbac.authorization.k8s.io"
  }

  dynamic "subject" {
    for_each = each.value.members
    content {
      kind      = "User"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "team-${each.value.access_level}"
    api_group = "rbac.authorization.k8s.io"
  }
}

# Note: Cross-team access is currently disabled due to complexity
# This can be re-enabled later with proper implementation
# For now, teams have access only to their designated namespaces

# ==============================================================================
# PLATFORM TEAM BINDINGS
# ==============================================================================

# Platform administrators
resource "kubernetes_cluster_role_binding" "platform_admins" {
  count = length(var.platform_admins) > 0 ? 1 : 0

  metadata {
    name = "platform-admin-binding"
    labels = {
      "rbac.platform/managed-by"   = "terraform"
      "rbac.platform/binding-type" = "platform-admin"
    }
    annotations = {
      "description" = "Platform engineering team - full cluster access"
    }
  }

  dynamic "subject" {
    for_each = var.platform_admins
    content {
      kind      = "User"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.platform_admin.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

# Platform operators
resource "kubernetes_cluster_role_binding" "platform_operators" {
  count = length(var.platform_operators) > 0 ? 1 : 0

  metadata {
    name = "platform-operator-binding"
    labels = {
      "rbac.platform/managed-by"   = "terraform"
      "rbac.platform/binding-type" = "platform-operator"
    }
    annotations = {
      "description" = "Platform operators - infrastructure management access"
    }
  }

  dynamic "subject" {
    for_each = var.platform_operators
    content {
      kind      = "User"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.platform_operator.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

# Platform viewers (monitoring, auditing, etc.)
resource "kubernetes_cluster_role_binding" "platform_viewers" {
  count = length(var.platform_viewers) > 0 ? 1 : 0

  metadata {
    name = "platform-viewer-binding"
    labels = {
      "rbac.platform/managed-by"   = "terraform"
      "rbac.platform/binding-type" = "platform-viewer"
    }
    annotations = {
      "description" = "Platform viewers - read-only cluster access"
    }
  }

  dynamic "subject" {
    for_each = var.platform_viewers
    content {
      kind      = "User"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.platform_viewer.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

# ==============================================================================
# SERVICE ACCOUNTS FOR CI/CD AND AUTOMATION
# ==============================================================================

# CI/CD Service Account for deployments
resource "kubernetes_service_account" "cicd_deployer" {
  for_each = var.teams

  metadata {
    name      = "${each.key}-cicd-deployer"
    namespace = kubernetes_namespace.team_namespaces[each.key].metadata[0].name
    labels = {
      "team"                      = each.key
      "rbac.platform/managed-by" = "terraform"
      "rbac.platform/purpose"    = "cicd-automation"
    }
    annotations = {
      "description" = "Service account for ${each.key} team CI/CD pipeline deployments"
    }
  }

  automount_service_account_token = true
}

# Bind CI/CD service accounts to deployment roles
resource "kubernetes_role_binding" "cicd_deployer_binding" {
  for_each = var.teams

  metadata {
    name      = "${each.key}-cicd-deployer-binding"
    namespace = kubernetes_namespace.team_namespaces[each.key].metadata[0].name
    labels = {
      "team"                        = each.key
      "rbac.platform/managed-by"   = "terraform"
      "rbac.platform/binding-type" = "service-account"
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cicd_deployer[each.key].metadata[0].name
    namespace = kubernetes_namespace.team_namespaces[each.key].metadata[0].name
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "team-${each.value.access_level}"
    api_group = "rbac.authorization.k8s.io"
  }
}