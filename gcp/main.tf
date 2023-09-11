provider "google" {
  credentials = file("gcp-credentials.json")
  project     = "rpl-research"
  region      = "asia-southeast1"
}

resource "google_compute_instance_template" "instance-template" {
  name         = "rpl-instance-template"
  machine_type = "e2-medium"
  region       = "asia-southeast1"

  network_interface {
    network = "default"
    access_config {

    }
  }

  disk {
    source_image = "debian-cloud/debian-11"
  }
}

resource "google_compute_health_check" "health-check" {
  name                = "rpl-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/health-check"
    port         = "8080"
  }
}

resource "google_compute_instance_group_manager" "instance-group-manager" {
  name = "rpl-instance-group"

  base_instance_name = "rpl-instance"
  zone               = "asia-southeast1-a"

  version {
    instance_template = google_compute_instance_template.instance-template.self_link
  }
  target_size = 1

  named_port {
    name = "customhttp"
    port = 8888
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}
