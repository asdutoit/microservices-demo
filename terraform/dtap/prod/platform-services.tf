# Platform Services Configuration for Production Environment

# NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  count = var.enable_nginx_ingress ? 1 : 0

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.nginx_ingress_chart_version
  namespace  = "ingress-nginx"

  create_namespace = true

  values = [
    yamlencode({
      controller = {
        replicaCount = 3  # High availability for production

        service = {
          type                = "LoadBalancer"
          loadBalancerSourceRanges = ["0.0.0.0/0"]
          annotations = {
            "cloud.google.com/load-balancer-type" = "External"
          }
        }

        # Resource limits for production
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

        # Node affinity to spread across zones
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [{
              weight = 100
              podAffinityTerm = {
                labelSelector = {
                  matchExpressions = [{
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["ingress-nginx"]
                  }]
                }
                topologyKey = "kubernetes.io/hostname"
              }
            }]
          }
        }

        # Production tolerations
        tolerations = [{
          key      = "production"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }]

        # Metrics and monitoring
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }

        # Autoscaling
        autoscaling = {
          enabled                           = true
          minReplicas                      = 3
          maxReplicas                      = 10
          targetCPUUtilizationPercentage   = 70
          targetMemoryUtilizationPercentage = 80
        }
      }
    })
  ]

  depends_on = [
    google_container_node_pool.primary_nodes
  ]
}

# Cert Manager for SSL certificates
resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_chart_version
  namespace  = "cert-manager"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "replicaCount"
    value = "2"  # High availability
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = "256Mi"
  }

  depends_on = [
    google_container_node_pool.primary_nodes
  ]
}

# Let's Encrypt ClusterIssuer for production
resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
  count = var.enable_cert_manager ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager,
    helm_release.nginx_ingress
  ]
}

# ArgoCD for GitOps
resource "kubernetes_namespace" "argocd" {
  count = var.enable_argocd ? 1 : 0

  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/instance" = "argocd"
      "app.kubernetes.io/part-of"  = "argocd"
      environment                  = "production"
    }
  }

  depends_on = [
    google_container_node_pool.primary_nodes
  ]
}

resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = "argocd"

  values = [
    yamlencode({
      global = {
        image = {
          tag = "v2.8.5"
        }
      }

      controller = {
        replicas = 2  # High availability
        resources = {
          requests = {
            cpu    = "500m"
            memory = "1Gi"
          }
          limits = {
            cpu    = "1000m"
            memory = "2Gi"
          }
        }
        tolerations = [{
          key      = "production"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }]
      }

      server = {
        replicas = 2  # High availability
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
        
        tolerations = [{
          key      = "production"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }]

        service = {
          type = "ClusterIP"
        }

        ingress = {
          enabled = true
          ingressClassName = "nginx"
          hostname = var.argocd_server_host
          annotations = {
            "cert-manager.io/cluster-issuer"                = "letsencrypt-prod"
            "nginx.ingress.kubernetes.io/ssl-redirect"      = "true"
            "nginx.ingress.kubernetes.io/backend-protocol"  = "GRPC"
            "nginx.ingress.kubernetes.io/grpc-backend"      = "true"
          }
          tls = [{
            secretName = "argocd-server-tls"
            hosts      = [var.argocd_server_host]
          }]
        }

        config = {
          "admin.enabled" = "true"
          "oidc.config" = yamlencode({
            name         = "Google"
            issuer       = "https://accounts.google.com"
            clientId     = "your-google-client-id"  # Replace with actual client ID
            clientSecret = "$oidc.google.clientSecret"
            requestedScopes = ["openid", "profile", "email"]
            requestedIDTokenClaims = {
              groups = {
                essential = true
              }
            }
          })
          "policy.default" = "role:readonly"
          "policy.csv" = <<-EOT
            p, role:admin, applications, *, */*, allow
            p, role:admin, clusters, *, *, allow
            p, role:admin, repositories, *, *, allow
            p, role:readonly, applications, get, */*, allow
            p, role:readonly, clusters, get, *, allow
            p, role:readonly, repositories, get, *, allow
            g, argocd-admins@example.com, role:admin
          EOT
        }
      }

      repoServer = {
        replicas = 2  # High availability
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
        tolerations = [{
          key      = "production"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }]
      }

      redis = {
        enabled = true
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
        tolerations = [{
          key      = "production"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }]
      }

      configs = {
        secret = {
          argocdServerAdminPassword = var.argocd_admin_password
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd,
    helm_release.nginx_ingress,
    helm_release.cert_manager
  ]
}

# Argo Rollouts for advanced deployment strategies
resource "helm_release" "argo_rollouts" {
  count = var.enable_argo_rollouts ? 1 : 0

  name       = "argo-rollouts"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = "2.32.2"
  namespace  = "argo-rollouts"

  create_namespace = true

  values = [
    yamlencode({
      controller = {
        replicas = 2  # High availability
        resources = {
          requests = {
            cpu    = "200m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
        tolerations = [{
          key      = "production"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }]
      }
      
      dashboard = {
        enabled = true
        ingress = {
          enabled = true
          ingressClassName = "nginx"
          hosts = ["argo-rollouts-prod.example.com"]
          annotations = {
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          }
          tls = [{
            secretName = "argo-rollouts-tls"
            hosts      = ["argo-rollouts-prod.example.com"]
          }]
        }
      }
    })
  ]

  depends_on = [
    google_container_node_pool.primary_nodes,
    helm_release.nginx_ingress,
    helm_release.cert_manager
  ]
}

# Prometheus monitoring stack
resource "helm_release" "prometheus" {
  count = var.enable_monitoring ? 1 : 0

  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_chart_version
  namespace  = "monitoring"

  create_namespace = true

  values = [
    yamlencode({
      # Prometheus server configuration
      prometheus = {
        prometheusSpec = {
          retention = "30d"  # 30 days retention for production
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "standard-rwo"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "100Gi"  # Large storage for production metrics
                  }
                }
              }
            }
          }
          resources = {
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
            limits = {
              cpu    = "1000m"
              memory = "4Gi"
            }
          }
          tolerations = [{
            key      = "production"
            operator = "Equal"
            value    = "true"
            effect   = "NoSchedule"
          }]
        }
      }

      # Grafana configuration
      grafana = {
        enabled = true
        adminPassword = var.grafana_admin_password
        ingress = {
          enabled = true
          ingressClassName = "nginx"
          hosts = ["grafana-prod.example.com"]
          annotations = {
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          }
          tls = [{
            secretName = "grafana-tls"
            hosts      = ["grafana-prod.example.com"]
          }]
        }
        resources = {
          requests = {
            cpu    = "200m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "1Gi"
          }
        }
        tolerations = [{
          key      = "production"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }]
        persistence = {
          enabled = true
          size = "10Gi"
          storageClassName = "standard-rwo"
        }
      }

      # AlertManager configuration
      alertmanager = {
        alertmanagerSpec = {
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
          tolerations = [{
            key      = "production"
            operator = "Equal"
            value    = "true"
            effect   = "NoSchedule"
          }]
        }
      }
    })
  ]

  depends_on = [
    google_container_node_pool.primary_nodes,
    helm_release.nginx_ingress,
    helm_release.cert_manager
  ]
}

# Fluent Bit for log aggregation
resource "helm_release" "fluent_bit" {
  count = var.enable_logging ? 1 : 0

  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.21.7"
  namespace  = "logging"

  create_namespace = true

  values = [
    yamlencode({
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
      tolerations = [{
        key      = "production"
        operator = "Equal"
        value    = "true"
        effect   = "NoSchedule"
      }]
      config = {
        outputs = |
          [OUTPUT]
              Name stackdriver
              Match *
              google_service_credentials /var/secrets/google/key.json
              export_to_project_id ${var.gcp_project_id}
              k8s_cluster_name ${var.cluster_name}
              k8s_cluster_location ${var.gcp_region}
        filters = |
          [FILTER]
              Name kubernetes
              Match kube.*
              Merge_Log On
              Keep_Log Off
              K8S-Logging.Parser On
              K8S-Logging.Exclude On
    })
  ]

  depends_on = [
    google_container_node_pool.primary_nodes
  ]
}