# Create namespace for NGINX Ingress Controller
resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "ingress-nginx"
  }

  depends_on = [module.dev_kubernetes_cluster]
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
    module.dev_kubernetes_cluster
  ]

  timeout = 300
}

# Output the LoadBalancer information
output "nginx_ingress_info" {
  description = "NGINX Ingress Controller LoadBalancer information"
  value = {
    namespace    = kubernetes_namespace.nginx_ingress.metadata[0].name
    service_name = "ingress-nginx-controller"
    # Note: LoadBalancer IP will be available after deployment
    # Run: kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    access_info = "Use 'kubectl get svc ingress-nginx-controller -n ingress-nginx' to get LoadBalancer IP"
    status      = helm_release.nginx_ingress.status
  }
}

# Backwards compatibility output
output "nginx_ingress_ip" {
  description = "NGINX Ingress Controller deployment status (use nginx_ingress_info for detailed info)"
  value       = "deployed"
}
