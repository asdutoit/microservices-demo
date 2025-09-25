resource "google_container_cluster" "my_cluster" {

  name     = var.name
  location = var.region

  # Enable autopilot for this cluster
  enable_autopilot = true

  # Configure network and subnetwork
  network    = var.vpc_name
  subnetwork = var.subnet_name

  # Configure IP allocation policy with custom ranges if provided
  dynamic "ip_allocation_policy" {
    for_each = var.ip_allocation_policy != null ? [var.ip_allocation_policy] : []
    content {
      cluster_secondary_range_name  = ip_allocation_policy.value.cluster_secondary_range_name
      services_secondary_range_name = ip_allocation_policy.value.services_secondary_range_name
    }
  }

  # Avoid setting deletion_protection to false
  # until you're ready (and certain you want) to destroy the cluster.
  deletion_protection = var.deletion_protection
}

# Get credentials for cluster using simple null_resource
resource "null_resource" "get_cluster_credentials" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.name} --region=${var.region} --project=${var.gcp_project_id}"
  }

  # Ensure this runs after cluster creation
  depends_on = [google_container_cluster.my_cluster]
}

# Apply YAML kubernetes-manifest configurations (only if not skipped)
resource "null_resource" "apply_deployment" {
  count = var.skip_app_deployment ? 0 : 1
  
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "kubectl apply -k ${var.filepath_manifest} -n ${var.namespace}"
  }

  depends_on = [
    null_resource.get_cluster_credentials
  ]
}

# Wait condition for all Pods to be ready before finishing (only if app deployed and pod wait not skipped)
resource "null_resource" "wait_conditions" {
  count = (var.skip_app_deployment || var.skip_pod_wait) ? 0 : 1
  
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = <<-EOT
    echo "⏳ Waiting for metrics API to be available..."
    kubectl wait --for=condition=AVAILABLE apiservice/v1beta1.metrics.k8s.io --timeout=300s || echo "Metrics API timeout - continuing anyway"
    
    echo "⏳ Waiting for pods to be ready (this may take 10-15 minutes on GKE Autopilot)..."
    kubectl wait --for=condition=ready pods --all -n ${var.namespace} --timeout=${var.pod_readiness_timeout}s || {
      echo "⚠️ Some pods are not ready yet. Checking pod status:"
      kubectl get pods -n ${var.namespace}
      kubectl describe pods -n ${var.namespace} | grep -E "Name:|State:|Events:" | tail -20
      echo "🔄 Deployment will continue - pods may still be starting"
    }
    
    echo "📊 Final pod status:"
    kubectl get pods -n ${var.namespace}
    EOT
  }

  depends_on = [
    null_resource.apply_deployment,
  ]
}

# ==============================================================================
# PLATFORM RBAC INTEGRATION
# ==============================================================================

# Integrate platform-level RBAC management
module "platform_rbac" {
  count  = var.enable_platform_rbac ? 1 : 0
  source = "../platform-rbac"

  # Pass through environment configuration
  environment    = var.rbac_environment
  project_name   = var.platform_project_name
  
  # Platform-level access
  platform_admins    = var.platform_admins
  platform_operators = var.platform_operators
  platform_viewers   = var.platform_viewers
  
  # Team-based access
  teams = var.rbac_teams
  
  # Ensure RBAC is deployed after cluster is ready
  depends_on = [
    google_container_cluster.my_cluster,
    null_resource.get_cluster_credentials
  ]
}
