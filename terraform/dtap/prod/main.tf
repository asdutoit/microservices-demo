terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  # Use Cloud Storage for state (production)
  backend "gcs" {
    bucket = "company-terraform-state-prod"  # Replace with actual bucket
    prefix = "terraform/state/prod"
  }
}

# Configure Google Provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  }
}

data "google_client_config" "default" {}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "online-boutique-prod-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"

  lifecycle {
    prevent_destroy = true
  }
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "online-boutique-prod-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc.id

  # Secondary IP ranges for pods and services
  secondary_ip_range {
    range_name    = "prod-pods"
    ip_cidr_range = "10.10.0.0/16"
  }

  secondary_ip_range {
    range_name    = "prod-services"
    ip_cidr_range = "10.20.0.0/16"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Cloud NAT Router
resource "google_compute_router" "router" {
  name    = "online-boutique-prod-router"
  region  = var.gcp_region
  network = google_compute_network.vpc.id
}

# Cloud NAT Gateway
resource "google_compute_router_nat" "nat" {
  name                               = "online-boutique-prod-nat"
  router                            = google_compute_router.router.name
  region                            = var.gcp_region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# GKE Cluster - Production configuration
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.gcp_region

  # Production cluster settings
  min_master_version = var.kubernetes_version
  network           = google_compute_network.vpc.name
  subnetwork        = google_compute_subnetwork.subnet.name

  # Production-grade cluster features
  enable_shielded_nodes     = true
  enable_network_policy     = true
  enable_intranode_visibility = true

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # IP allocation policy
  ip_allocation_policy {
    cluster_secondary_range_name  = "prod-pods"
    services_secondary_range_name = "prod-services"
  }

  # Network policy
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"  # 3 AM UTC for production
    }
  }

  # Master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"  # In production, restrict this to your IP ranges
      display_name = "External access"
    }
  }

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Binary authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      node_config,
    ]
  }

  depends_on = [
    google_compute_subnetwork.subnet
  ]
}

# Primary Node Pool - Production workloads
resource "google_container_node_pool" "primary_nodes" {
  name       = "prod-primary-nodes"
  location   = var.gcp_region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  # Production node configuration
  node_config {
    preemptible     = false  # No preemptible nodes in production
    machine_type    = var.node_machine_type
    disk_size_gb    = 100
    disk_type       = "pd-ssd"
    image_type      = "COS_CONTAINERD"

    # Google service account
    service_account = google_service_account.gke_node_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded Instance features
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = {
      environment = "production"
      nodepool    = "primary"
    }

    taint {
      key    = "production"
      value  = "true"
      effect = "NO_SCHEDULE"
    }

    tags = ["gke-node", "prod"]
  }

  # Autoscaling configuration
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  # Node management
  management {
    auto_repair  = true
    auto_upgrade = false  # Manual upgrades in production
  }

  # Upgrade settings
  upgrade_settings {
    strategy         = "SURGE"
    max_surge        = 1
    max_unavailable  = 0  # Zero downtime upgrades
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }

  depends_on = [
    google_container_cluster.primary
  ]
}

# Service Account for GKE nodes
resource "google_service_account" "gke_node_sa" {
  account_id   = "gke-prod-node-sa"
  display_name = "GKE Production Node Service Account"
  description  = "Service account for GKE production cluster nodes"
}

# IAM bindings for GKE node service account
resource "google_project_iam_member" "gke_node_sa_bindings" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])

  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

# Firewall rules for production
resource "google_compute_firewall" "allow_internal" {
  name    = "online-boutique-prod-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.subnet_cidr, "10.10.0.0/16", "10.20.0.0/16"]
  target_tags   = ["gke-node"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "online-boutique-prod-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]  # IAP IP range
  target_tags   = ["gke-node"]
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "online-boutique-prod-allow-health-checks"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]
  target_tags = ["gke-node"]
}