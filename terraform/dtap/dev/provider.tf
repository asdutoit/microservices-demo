terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.49.3"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.49.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.region
}

# Kubernetes provider - use gke auth plugin
provider "kubernetes" {
  host                   = "https://${module.dev_kubernetes_cluster.cluster_endpoint}"
  cluster_ca_certificate = base64decode(module.dev_kubernetes_cluster.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gke-gcloud-auth-plugin"
  }
}

# Helm provider - use gke auth plugin
provider "helm" {
  kubernetes {
    host                   = "https://${module.dev_kubernetes_cluster.cluster_endpoint}"
    cluster_ca_certificate = base64decode(module.dev_kubernetes_cluster.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}

