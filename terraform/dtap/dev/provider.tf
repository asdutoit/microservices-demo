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

provider "kubernetes" {
  host                   = "https://${module.cluster_vpc.endpoint}"
  cluster_ca_certificate = base64decode(module.cluster_vpc.ca_certificate)
  token                  = data.google_client_config.default.access_token
}

