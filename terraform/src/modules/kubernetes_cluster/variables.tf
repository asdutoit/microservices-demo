variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID to apply this config to"
}

variable "name" {
  type        = string
  description = "Name given to the new GKE cluster"
  default     = "online-boutique"
}

variable "region" {
  type        = string
  description = "Region of the new GKE cluster"
  default     = "us-central1"
}

variable "namespace" {
  type        = string
  description = "Kubernetes Namespace in which the Online Boutique resources are to be deployed"
  default     = "default"
}

variable "filepath_manifest" {
  type        = string
  description = "Path to Online Boutique's Kubernetes resources, written using Kustomize"
  default     = "../kustomize/"
}

variable "memorystore" {
  type        = bool
  description = "If true, Online Boutique's in-cluster Redis cache will be replaced with a Google Cloud Memorystore Redis cache"
  default     = false
}


variable "vpc_name" {
  description = "The name of the VPC network to deploy the GKE cluster into"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnetwork to deploy the GKE cluster into"
  type        = string
}

variable "deletion_protection" {
  description = "If true, the GKE cluster will have deletion protection enabled"
  type        = bool
  default     = true
}

variable "ip_allocation_policy" {
  description = "Configuration block for IP allocation policy"
  type = object({
    cluster_secondary_range_name  = string
    services_secondary_range_name = string
  })
  default = null
}

variable "apis_dependency" {
  description = "Dependency on API enablement"
  type        = any
  default     = null
}