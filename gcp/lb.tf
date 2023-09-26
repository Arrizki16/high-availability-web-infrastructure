resource "google_compute_global_address" "lb-ip" {
  name        = "lb-ip"
  description = "Global IP address for the Load Balancer"
  ip_version  = "IPV4"
  purpose     = "GLOBAL"
}

resource "google_compute_health_check" "lb-health-check" {
  name               = "lb-health-check-test"
  check_interval_sec = 10
  timeout_sec        = 5

  http_health_check {
    request_path = "/"
    port         = "80"
    response     = "lb ok"
  }
}

resource "google_compute_backend_service" "backend-service" {
  name        = "backend-service-test"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  depends_on  = [google_compute_health_check.lb-health-check, google_compute_instance_group_manager.instance-group-manager]

  backend {
    group = google_compute_instance_group_manager.instance-group-manager.id
  }

  health_checks = [google_compute_health_check.lb-health-check.id]
}

resource "google_compute_url_map" "url-map" {
  name            = "url-map-test"
  default_service = google_compute_backend_service.backend-service.id

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.backend-service.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.backend-service.id
    }
  }
}

resource "google_compute_target_http_proxy" "http-proxy" {
  name    = "http-proxy-test"
  url_map = google_compute_url_map.url-map.id
}

resource "google_compute_forwarding_rule" "forwarding-rule" {
  name                  = "forwarding-rule-test"
  description           = "Forwarding rule for the Load Balancer"
  target                = google_compute_target_http_proxy.http-proxy.id
  port_range            = "80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.lb-ip.address
}