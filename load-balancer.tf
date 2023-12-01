resource "yandex_lb_network_load_balancer" "lb-bingo" {
  name = "bingo"

  listener {
    name        = "cat-bingo"
    port        = 80
    target_port = 8080
    external_address_spec {
      ip_version = "ipv4"
    }    
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.foo.id

    healthcheck {
      name = "http"
      http_options {
        port = 8080
        path = "/ping"
      }
    }
  }
}
