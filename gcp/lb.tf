resource "google_compute_forwarding_rule" "forwarding-rule" {
  name                  = "forwarding-rule-test"
  description           = "Forwarding rule for the Load Balancer"
  target                = google_compute_target_http_proxy.default.id
  port_range            = "80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  global                = true
  ip_address            = google_compute_global_address.lb-ip.address
}

resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy-test"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_url_map" "default" {
  name            = "url-map-test"
  default_service = google_compute_backend_service.default.id

  host_rule {
    hosts        = ["mysite.com"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.default.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.default.id
    }
  }
}

resource "google_compute_backend_service" "default" {
  name        = "backend-service-test"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group_manager.instance-group-manager.id
  }

  health_checks = [google_compute_http_health_check.health-check.id]
}
