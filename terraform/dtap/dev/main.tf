
module "enable_google_apis" {
  source = "../../src/modules/enable_google_apis/"

  gcp_project_id      = var.gcp_project_id
  google_cluster_name = var.name

  apis = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com"
  ]

  memorystore_apis = [
    "redis.googleapis.com"
  ]
}

module "cluster_vpc" {
  source = "../../src/modules/vpc/"

  gcp_project_id = var.gcp_project_id
  region         = var.region
  vpc_name       = "${var.name}-vpc"
  subnet_name    = "${var.name}-subnet"

  ip_cidr_range = "10.0.0.0/16"

  secondary_ip_ranges = [
    {
      range_name    = "pods"
      ip_cidr_range = "10.1.0.0/16"
    },
    {
      range_name    = "services"
      ip_cidr_range = "10.2.0.0/16"
    }
  ]

  depends_on = [
    module.enable_google_apis
  ]
}

module "dev_kubernetes_cluster" {
  source = "../../src/modules/kubernetes_cluster/"

  gcp_project_id             = var.gcp_project_id
  name                       = var.name
  region                     = var.region
  namespace                  = var.namespace
  # Skip application deployment in CI/CD mode to focus on infrastructure
  filepath_manifest          = (var.ci_cd_mode || var.skip_app_deployment) ? "/dev/null" : var.filepath_manifest
  memorystore                = var.memorystore
  enable_rbac_cluster_access = var.enable_rbac_cluster_access

  # Platform RBAC integration - managed by platform-rbac module
  # Disable RBAC in CI/CD mode to simplify deployments
  enable_platform_rbac  = var.ci_cd_mode ? false : var.enable_platform_rbac
  platform_admins       = var.platform_admins
  platform_operators    = var.platform_operators
  platform_viewers      = var.platform_viewers
  rbac_teams            = var.rbac_teams
  rbac_environment      = "dev"
  platform_project_name = "online-boutique"

  vpc_name    = module.cluster_vpc.vpc_name
  subnet_name = module.cluster_vpc.subnet_name

  ip_allocation_policy = {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  deletion_protection = "false"

  depends_on = [
    module.enable_google_apis,
    module.cluster_vpc
  ]
}
