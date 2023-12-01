resource "yandex_compute_instance_group" "bingo-group1" {
  name               = "bingo-group1"
  service_account_id = "aje3lpbjt2nhcn42nigt"
  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  instance_template {
    platform_id        = "standard-v2"

    resources {
      cores         = 4
      memory        = 8
      core_fraction = 5
    }

    scheduling_policy {
      preemptible = false
    }

    network_interface {
      network_id = yandex_vpc_network.bingo-network.id
      subnet_ids = ["${yandex_vpc_subnet.bingo-subnet-a.id}"]
      nat        = true
    }

    boot_disk {
      initialize_params {
        type     = "network-hdd"
        size     = "30"
        image_id = "fd8un8f40qgmlenpa0qb"
      }
    }

    metadata = {
      ssh-keys  = "{var.user_name}:${file("~/.ssh/id_rsa.pub")}"
    }
  }

  load_balancer {
    target_group_name            = "bingo"
    max_opening_traffic_duration = 30
  }
}

resource "yandex_lb_network_load_balancer" "lb-bingo" {
  name = "bingo-lb"

  listener {
    name        = "bingo-listener"
    port        = 80
    target_port = 8080
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  listener {
    name        = "bingo-listener-2"
    port        = 443
    target_port = 443
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.bingo-group1.load_balancer[0].target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 8080
        path = "/ping"
      }
    }
  }
}



