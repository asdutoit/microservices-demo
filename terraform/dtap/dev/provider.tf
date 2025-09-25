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

# Kubernetes provider - use kubectl config-based authentication
# This relies on kubectl being properly configured by the cluster module
provider "kubernetes" {
  # Don't specify host/token - let it use kubectl config
  # The kubernetes_cluster module configures kubectl via null_resource
  config_path = "~/.kube/config"
}

# Helm provider - use kubectl config-based authentication
provider "helm" {
  kubernetes {
    # Don't specify host/token - let it use kubectl config
    # The kubernetes_cluster module configures kubectl via null_resource
    config_path = "~/.kube/config"
  }
}

