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

# Kubernetes provider - use data source with fallbacks for better reliability
provider "kubernetes" {
  host                   = try("https://${data.google_container_cluster.cluster.endpoint}", null)
  cluster_ca_certificate = try(base64decode(data.google_container_cluster.cluster.master_auth.0.cluster_ca_certificate), null)
  token                  = data.google_client_config.default.access_token

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gke-gcloud-auth-plugin"
  }
}

# Helm provider - use data source with fallbacks for better reliability
provider "helm" {
  kubernetes {
    host                   = try("https://${data.google_container_cluster.cluster.endpoint}", null)
    cluster_ca_certificate = try(base64decode(data.google_container_cluster.cluster.master_auth.0.cluster_ca_certificate), null)
    token                  = data.google_client_config.default.access_token

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}

