provider "google" {
  credentials = file("csql-ce-cs.json")
  project     = "able-tide-404304"
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
  machine_type = "e2-small"
  region       = "asia-southeast1"
  tags         = ["allow-http", "allow-ssh"]

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
    startup-script = <<EOF
#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y nginx git mysql-client
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

sudo npm install pm2 -g

sudo git clone https://github.com/Arrizki16/high-availability-web-infrastructure.git /var/www/app/

cd /var/www/app/src-gcp
sudo echo 'DB_NAME="rpl"
DB_USER="root"
DB_PASSWORD="password"
DB_HOST="34.124.217.158"
DB_PORT=3306' > .env

sudo npm install
sudo pm2 start ecosystem.config.cjs

sudo echo "server {  
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}" > /etc/nginx/sites-available/app.conf

sudo ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
EOF
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
  target_size        = 1
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "rpl-instance-group-autoscaler"
  zone   = "asia-southeast1-a"
  target = google_compute_instance_group_manager.instance-group-manager.id

  autoscaling_policy {
    max_replicas    = 8
    min_replicas    = 1
    cooldown_period = 120

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

resource "google_compute_firewall" "ssh-allow" {
  name        = "rpl-allow-ssh"
  network     = google_compute_network.rpl-vpc-network.id
  description = "Allow incoming SSH"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["allow-ssh"]
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