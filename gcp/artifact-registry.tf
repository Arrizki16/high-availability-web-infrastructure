resource "google_artifact_registry_repository" "registry-repository" {
  location      = "asia-southeast1"
  repository_id = "rpl-repository"
  description   = "repository for rpl application"
  format        = "DOCKER"
}