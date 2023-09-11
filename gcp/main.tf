provider "google" {
  credentials = file("gcp-credentials.json")
  project     = "rpl-research"
  region      = "asia-southeast2"
}

resource "google_compute_instance" "rpl-instance" {
  name         = "rpl-instance"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"
  
  network_interface {
    network = "default"
    access_config {

    }
  }
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
}