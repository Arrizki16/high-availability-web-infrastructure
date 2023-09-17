provider "google" {
  credentials = file("gcp-credentials.json")
  project     = "rpl-research"
  region      = "asia-southeast1"
}

resource "google_compute_instance_template" "instance-template" {
  name         = "rpl-instance-template"
  machine_type = "e2-micro"
  region       = "asia-southeast1"

  network_interface {
    network = "default"
    access_config {

    }
  }

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
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
    health_check      = google_compute_health_check.health-check.id
    initial_delay_sec = 300
  }
}

resource "google_compute_backend_service" "backend-service" {
  name                    = "rpl-backend-service"
  protocol                = "HTTP"
  timeout_sec             = 30
  enable_cdn              = false

  backend {
    group = google_compute_instance_group_manager.instance-group-manager.id
  }

  health_checks = ["${google_compute_health_check.health-check.id}"]
}

resource "google_compute_url_map" "url-map" {
  name            = "rpl-url-map"
  default_service = google_compute_backend_service.backend-service.id
}

resource "google_compute_global_forwarding_rule" "global-forwarding-rule" {
  name        = "rpl-forwarding-rule"
  target      = google_compute_url_map.url-map.id
  port_range  = "80"
  ip_protocol = "TCP"
}

resource "google_compute_firewall" "firewall" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}