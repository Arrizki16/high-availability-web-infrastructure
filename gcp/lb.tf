resource "google_compute_global_address" "lb-ip" {
  name        = "rpl-static-ip"
  description = "Global IP address for the Load Balancer"
  ip_version  = "IPV4"
  purpose     = "GLOBAL"
}

resource "google_compute_health_check" "health-check" {
  name     = "rpl-health-check"
  check_interval_sec = 10
  timeout_sec = 10
  healthy_threshold = 2
  unhealthy_threshold = 2 

  http_health_check {
    port = 80
    request_path = "/api/version"
  }
}

resource "google_compute_backend_service" "backend-service" {
  name                  = "rpl-backend-service"
  port_name             = "http"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 10
  depends_on            = [google_compute_health_check.health-check, google_compute_instance_group_manager.instance-group-manager]

  backend {
    group           = google_compute_instance_group_manager.instance-group-manager.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_health_check.health-check.id]
}

resource "google_compute_url_map" "url-map" {
  name            = "rpl-url-map"
  default_service = google_compute_backend_service.backend-service.id
}

resource "google_compute_target_http_proxy" "http-proxy" {
  name    = "rpl-target-http-proxy"
  url_map = google_compute_url_map.url-map.id
}

resource "google_compute_global_forwarding_rule" "forwarding-rule" {
  name                  = "rpl-forwarding-rule"
  description           = "Forwarding rule for the Load Balancer"
  target                = google_compute_target_http_proxy.http-proxy.id
  port_range            = "80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.lb-ip.address
}