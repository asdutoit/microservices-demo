terraform {
  backend "gcs" {
    bucket = "test-gcp-training-asdutoit"
    prefix = "terraform/state/dev"
  }
}