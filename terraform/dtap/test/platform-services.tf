# Platform services for Test environment
# This file deploys NGINX Ingress, ArgoCD, and Argo Rollouts

# Create namespace for NGINX Ingress Controller
resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "ingress-nginx"
  }

  depends_on = [module.test_kubernetes_cluster]
}

# Install NGINX Ingress Controller using Helm
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.3"
  namespace  = kubernetes_namespace.nginx_ingress.metadata[0].name

  # Values for GKE configuration
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.annotations.cloud\\.google\\.com/load-balancer-type"
    value = "External"
  }

  # Enable GCE ingress class for compatibility
  set {
    name  = "controller.ingressClassResource.name"
    value = "nginx"
  }

  set {
    name  = "controller.ingressClassResource.controllerValue"
    value = "k8s.io/ingress-nginx"
  }

  set {
    name  = "controller.ingressClassResource.enabled"
    value = "true"
  }

  set {
    name  = "controller.ingressClass"
    value = "nginx"
  }

  # Optimize for GKE Autopilot
  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "90Mi"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "200Mi"
  }

  # Enable metrics
  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  depends_on = [
    kubernetes_namespace.nginx_ingress,
    module.test_kubernetes_cluster
  ]

  timeout = 300
}

# Create namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "argocd"
    }
  }

  depends_on = [module.test_kubernetes_cluster]
}

# Install ArgoCD CRDs first (following best practices)
resource "null_resource" "argocd_crds" {
  provisioner "local-exec" {
    command = "kubectl apply -k https://github.com/argoproj/argo-cd/manifests/crds?ref=stable"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -k https://github.com/argoproj/argo-cd/manifests/crds?ref=stable --ignore-not-found=true"
  }

  depends_on = [
    kubernetes_namespace.argocd,
    module.test_kubernetes_cluster
  ]
}

# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.11" # Use specific version for stability
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  
  # Disable CRD installation in Helm since we handle it explicitly above
  skip_crds = true

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
        #       host = "argocd-test.${var.domain_name != "" ? var.domain_name : "example.com"}"
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
          enabled = false  # Disabled - using LoadBalancer service with public IP
        }
        # Enable insecure mode for development
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
    null_resource.argocd_crds,      # Ensure CRDs are installed first
    helm_release.nginx_ingress,
    module.test_kubernetes_cluster
  ]

  timeout = 600
}

# Create namespace for Argo Rollouts
resource "kubernetes_namespace" "argo_rollouts" {
  metadata {
    name = "argo-rollouts"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "argo-rollouts"
    }
  }

  depends_on = [module.test_kubernetes_cluster]
}

# Install Argo Rollouts CRDs first (as recommended by the documentation)
resource "null_resource" "argo_rollouts_crds" {
  provisioner "local-exec" {
    command = "kubectl apply -k https://github.com/argoproj/argo-rollouts/manifests/crds?ref=stable"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -k https://github.com/argoproj/argo-rollouts/manifests/crds?ref=stable --ignore-not-found=true"
  }

  depends_on = [
    kubernetes_namespace.argo_rollouts,
    module.test_kubernetes_cluster
  ]
}

# Install Argo Rollouts using Helm
resource "helm_release" "argo_rollouts" {
  name       = "argo-rollouts"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = "2.38.1" # Use the latest stable version
  namespace  = kubernetes_namespace.argo_rollouts.metadata[0].name
  
  # Disable CRD installation in Helm since we handle it explicitly above
  skip_crds = true

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
            enabled = false  # Disabled because Prometheus Operator is not installed
          }
        }
      }

      # Install dashboard with LoadBalancer for public access
      dashboard = {
        enabled = true
        service = {
          type = "LoadBalancer"  # Use LoadBalancer for public IP access
        }
        # Domain-based ingress (commented out - using LoadBalancer service instead)
        # Uncomment to use ingress with custom domain
        # ingress = {
        #   enabled          = true
        #   ingressClassName = "nginx"
        #   hosts = [
        #     {
        #       host = "rollouts-test.${var.domain_name != "" ? var.domain_name : "example.com"}"
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
          enabled = false  # Disabled - using LoadBalancer service with public IP
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
    null_resource.argo_rollouts_crds,  # Ensure CRDs are installed first
    helm_release.nginx_ingress,
    module.test_kubernetes_cluster
  ]

  timeout = 300
}

# Output NGINX Ingress information
output "nginx_ingress_info" {
  description = "NGINX Ingress Controller LoadBalancer information"
  value = {
    namespace    = kubernetes_namespace.nginx_ingress.metadata[0].name
    service_name = "ingress-nginx-controller"
    # Note: LoadBalancer IP will be available after deployment
    access_info  = "Use 'kubectl get svc ingress-nginx-controller -n ingress-nginx' to get LoadBalancer IP"
    status       = helm_release.nginx_ingress.status
  }
}

# Output ArgoCD server information
output "argocd_server_info" {
  description = "ArgoCD server connection information"
  value = {
    namespace    = kubernetes_namespace.argocd.metadata[0].name
    service_name = "argocd-server"
    username     = "admin"
    # Note: LoadBalancer IP will be available after deployment
    access_info  = "Use 'kubectl get svc argocd-server -n argocd' to get LoadBalancer IP"
    # Domain-based access (if ingress is enabled):
    # domain_url = "https://argocd-test.${var.domain_name != "" ? var.domain_name : "example.com"}"
  }
}

# Output Argo Rollouts information
output "argo_rollouts_info" {
  description = "Argo Rollouts dashboard connection information"
  value = {
    namespace    = kubernetes_namespace.argo_rollouts.metadata[0].name
    service_name = "argo-rollouts-dashboard"
    # Note: LoadBalancer IP will be available after deployment
    access_info  = "Use 'kubectl get svc argo-rollouts-dashboard -n argo-rollouts' to get LoadBalancer IP"
    # Domain-based access (if ingress is enabled):
    # domain_url = "https://rollouts-test.${var.domain_name != "" ? var.domain_name : "example.com"}"
  }
}