variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID to apply this config to"
}

variable "memorystore" {
  type        = bool
  description = "If true, Online Boutique's in-cluster Redis cache will be replaced with a Google Cloud Memorystore Redis cache"
  default     = false
}

variable "google_cluster_name" {
  type        = string
  description = "The name of the GKE cluster to be created"
}

variable "apis" {
  type        = list(string)
  description = "List of Google Cloud APIs to be enabled"
  default = [
    "container.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
    "cloudprofiler.googleapis.com",
    "compute.googleapis.com"
  ]
}

variable "memorystore_apis" {
  type        = list(string)
  description = "List of Google Cloud APIs required for Memorystore"
  default = [
    "redis.googleapis.com"
  ]
}