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
  description         = "Intance health check via http"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/"
    port         = "8080"
    response     = "ok"
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
    port = 8080
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.health-check.id
    initial_delay_sec = 300
  }
}

resource "google_compute_firewall" "http-allow" {
  name        = "allow-http"
  network     = "default"
  description = "Allow incoming HTTP traffic"
  
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "health-check-allow" {
  name        = "allow-health-check"
  network     = "default"
  description = "Allow health check traffic"
  
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}