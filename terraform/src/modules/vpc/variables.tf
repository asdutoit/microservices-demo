variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID to apply this config to"
}

variable "routing_mode" {
  type        = string
  description = "The routing mode of the VPC network"
  default     = "REGIONAL"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC network"
  default     = "online-boutique-vpc"
}

variable "subnet_name" {
  type        = string
  description = "The name of the VPC subnet"
  default     = "online-boutique-subnet"
}

variable "region" {
  type        = string
  description = "Region of the vpc network"
  default     = "us-central1"
}

variable "ip_cidr_range" {
  type        = string
  description = "The primary IP CIDR range for the VPC subnet"
  default     = "10.0.0.0/16"
}

variable "secondary_ip_ranges" {
  type = list(object({
    range_name    = string
    ip_cidr_range = string
  }))
  description = "A list of secondary IP ranges for the VPC subnet"
  # default = [
  #   {
  #     range_name    = "pods"
  #     description = "The secondary IP CIDR range for the pods in the VPC subnet"
  #     ip_cidr_range = "10.1.0.0/16"
  #   },
  #   {
  #     range_name    = "services"
  #     description = "The secondary IP CIDR range for the services in the VPC subnet"
  #     ip_cidr_range = "10.2.0.0/16"
  #   }
  # ]
}
