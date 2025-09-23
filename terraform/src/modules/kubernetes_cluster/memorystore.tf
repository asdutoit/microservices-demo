# Create the Memorystore (redis) instance
resource "google_redis_instance" "redis-cart" {
  count = var.memorystore ? 1 : 0

  name           = "redis-cart"
  memory_size_gb = 1
  region         = var.region
  redis_version  = "REDIS_7_0"
  project        = var.gcp_project_id

  depends_on = [var.apis_dependency]
}

# Edit contents of Memorystore kustomization.yaml file to target new Memorystore (redis) instance
resource "null_resource" "kustomization-update" {
  count = var.memorystore ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "sed -i \"s/REDIS_CONNECTION_STRING/${google_redis_instance.redis-cart[0].host}:${google_redis_instance.redis-cart[0].port}/g\" ../kustomize/components/memorystore/kustomization.yaml"
  }


  depends_on = [
    resource.google_redis_instance.redis-cart
  ]
}
