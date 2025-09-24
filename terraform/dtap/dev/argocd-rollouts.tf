# Create namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "argocd"
      "app.kubernetes.io/component"  = "argocd"
    }
  }

  depends_on = [module.dev_kubernetes_cluster]
}

# ArgoCD CRDs will be managed by Helm directly

# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.11" # Use specific version for stability
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Let Helm manage CRDs directly
  skip_crds = false

  # Core ArgoCD configuration
  values = [
    yamlencode({
      # Configure ArgoCD server
      server = {
        service = {
          type = "LoadBalancer"
        }
        # Domain-based ingress (commented out - use LoadBalancer service with public IP instead)
        # Uncomment and configure domain_name variable to use custom domain
        # ingress = {
        #   enabled          = true
        #   ingressClassName = "nginx"
        #   annotations = {
        #     "nginx.ingress.kubernetes.io/ssl-redirect"     = "true"
        #     "nginx.ingress.kubernetes.io/backend-protocol" = "GRPC"
        #     "nginx.ingress.kubernetes.io/grpc-backend"     = "true"
        #   }
        #   hosts = [
        #     {
        #       host = "argocd.${var.domain_name != "" ? var.domain_name : "example.com"}"
        #       paths = [
        #         {
        #           path     = "/"
        #           pathType = "Prefix"
        #         }
        #       ]
        #     }
        #   ]
        # }
        ingress = {
          enabled = false # Disabled - using LoadBalancer service with public IP
        }
        # Enable insecure mode for local development
        extraArgs = [
          "--insecure"
        ]
      }

      # Configure ArgoCD notifications controller
      notifications = {
        enabled = true
      }

      # Configure ArgoCD application controller
      controller = {
        resources = {
          requests = {
            cpu    = "250m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "1Gi"
          }
        }
      }

      # Configure ArgoCD repo server
      repoServer = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "512Mi"
          }
        }
      }

      # Configure RBAC
      configs = {
        params = {
          "server.insecure" = true
        }
        rbac = {
          "policy.default" = "role:readonly"
          "policy.csv"     = <<-EOT
            p, role:admin, applications, *, */*, allow
            p, role:admin, clusters, *, *, allow
            p, role:admin, repositories, *, *, allow
            p, role:admin, projects, *, *, allow
            g, argocd-admin, role:admin
          EOT
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd,
    helm_release.nginx_ingress,
    module.dev_kubernetes_cluster
  ]

  timeout = 600
}

# Create namespace for Argo Rollouts
resource "kubernetes_namespace" "argo_rollouts" {
  metadata {
    name = "argo-rollouts"
    labels = {
      "app.kubernetes.io/managed-by" = "argo-rollouts"
      "app.kubernetes.io/component"  = "argo-rollouts"
    }
  }

  depends_on = [module.dev_kubernetes_cluster]
}

# Argo Rollouts CRDs will be managed by Helm directly

# Install Argo Rollouts using Helm
resource "helm_release" "argo_rollouts" {
  name       = "argo-rollouts"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = "2.38.1" # Use the latest stable version
  namespace  = kubernetes_namespace.argo_rollouts.metadata[0].name

  # Let Helm manage CRDs directly
  skip_crds = false

  values = [
    yamlencode({
      # Configure Argo Rollouts controller
      controller = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
        # Enable metrics
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = false # Disabled because Prometheus Operator is not installed
          }
        }
      }

      # Install dashboard with LoadBalancer for public access
      dashboard = {
        enabled = true
        service = {
          type = "LoadBalancer" # Use LoadBalancer for public IP access
        }
        # Domain-based ingress (commented out - using LoadBalancer service instead)
        # Uncomment to use ingress with custom domain
        # ingress = {
        #   enabled          = true
        #   ingressClassName = "nginx"
        #   hosts = [
        #     {
        #       host = "rollouts.${var.domain_name != "" ? var.domain_name : "example.com"}"
        #       paths = [
        #         {
        #           path     = "/"
        #           pathType = "Prefix"
        #         }
        #       ]
        #     }
        #   ]
        # }
        ingress = {
          enabled = false # Disabled - using LoadBalancer service with public IP
        }
      }

      # Enable notifications
      notifications = {
        enabled = true
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.argo_rollouts,
    helm_release.nginx_ingress,
    module.dev_kubernetes_cluster
  ]

  timeout = 300
}

# Create a secret for ArgoCD admin password (optional)
resource "kubernetes_secret" "argocd_admin_password" {
  count = var.argocd_admin_password != "" ? 1 : 0

  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    password = base64encode(bcrypt(var.argocd_admin_password))
  }

  depends_on = [
    kubernetes_namespace.argocd,
    helm_release.argocd
  ]
}

# Output ArgoCD server information
output "argocd_server_info" {
  description = "ArgoCD server connection information"
  value = {
    namespace    = kubernetes_namespace.argocd.metadata[0].name
    service_name = "argocd-server"
    username     = "admin"
    # Note: LoadBalancer IP will be available after deployment
    # Run: kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    access_info = "Use 'kubectl get svc argocd-server -n argocd' to get LoadBalancer IP"
    # Domain-based access (if ingress is enabled):
    # domain_url = "https://argocd.${var.domain_name != "" ? var.domain_name : "example.com"}"
  }
}

# Output Argo Rollouts information
output "argo_rollouts_info" {
  description = "Argo Rollouts dashboard connection information"
  value = {
    namespace    = kubernetes_namespace.argo_rollouts.metadata[0].name
    service_name = "argo-rollouts-dashboard"
    # Note: LoadBalancer IP will be available after deployment
    # Run: kubectl get svc argo-rollouts-dashboard -n argo-rollouts -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    access_info = "Use 'kubectl get svc argo-rollouts-dashboard -n argo-rollouts' to get LoadBalancer IP"
    # Domain-based access (if ingress is enabled):
    # domain_url = "https://rollouts.${var.domain_name != "" ? var.domain_name : "example.com"}"
  }
}
