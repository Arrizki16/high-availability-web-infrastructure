provider "google" {
  credentials = file("gcp-credentials.json")
  project     = "rpl-research"
  region      = "asia-southeast1"
}

resource "google_compute_target_pool" "instance-pool" {
  name = "rpl-instance-pool"
}

resource "google_compute_instance_template" "instance-template" {
  name         = "rpl-instance-template-test"
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
  name                = "rpl-health-check-test"
  description         = "Intance health check via http"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/"
    port         = "80"
    response     = "ok"
  }
}

resource "google_compute_instance_group_manager" "instance-group-manager" {
  name = "rpl-instance-group-test"

  target_pools       = [google_compute_target_pool.instance-pool.id]
  base_instance_name = "rpl-instance-test"
  zone               = "asia-southeast1-a"

  version {
    instance_template = google_compute_instance_template.instance-template.id
  }
  target_size = 1

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.health-check.id
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "rpl-instance-group-autoscaler"
  zone   = "asia-southeast1-a"
  target = google_compute_instance_group_manager.instance-group-manager.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.7
    }
  }
}

resource "google_compute_firewall" "http-allow" {
  name        = "allow-http-test"
  network     = "default"
  description = "Allow incoming HTTP traffic"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags   = ["app-server"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "health-check-allow" {
  name        = "allow-health-check-test"
  network     = "default"
  description = "Allow health check traffic"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags   = ["app-server"]
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}