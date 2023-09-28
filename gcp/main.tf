provider "google" {
  credentials = file("gcp-credentials.json")
  project     = "rpl-research"
  region      = "asia-southeast1"
}

resource "google_compute_network" "rpl-vpc-network" {
  name                    = "rpl-vpc-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "rpl-backend-subnet" {
  name          = "rpl-backend-subnet"
  ip_cidr_range = "10.148.0.0/24"
  region        = "asia-southeast1"
  network       = google_compute_network.rpl-vpc-network.id
}

resource "google_compute_instance_template" "instance-template" {
  name         = "rpl-instance-template"
  machine_type = "e2-micro"
  region       = "asia-southeast1"
  tags         = ["allow-http"]

  network_interface {
    network    = google_compute_network.rpl-vpc-network.id
    subnetwork = google_compute_subnetwork.rpl-backend-subnet.id
    access_config {

    }
  }

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
  }

  metadata = {
    startup-script = <<-EOF1
      #! /bin/bash
      set -euo pipefail

      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y nginx-light jq

      NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
      IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
      METADATA=$(curl -f -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=True" | jq 'del(.["startup-script"])')

      cat <<EOF > /var/www/html/index.html
      <pre>
      Name: $NAME
      IP: $IP
      Metadata: $METADATA
      </pre>
      EOF
    EOF1
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "instance-group-manager" {
  name     = "rpl-instance-group-manager"
  zone     = "asia-southeast1-a"
  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template = google_compute_instance_template.instance-template.id
    name              = "primary"
  }
  base_instance_name = "rpl-instance"
  target_size        = 2
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
  name        = "rpl-allow-http"
  network     = google_compute_network.rpl-vpc-network.id
  description = "Allow incoming HTTP traffic"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags   = ["allow-http"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "hc-firewall" {
  name          = "rp-allow-health-check"
  direction     = "INGRESS"
  network       = google_compute_network.rpl-vpc-network.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check"]
}