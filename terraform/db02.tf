resource "yandex_compute_instance" "db-02" {

  name                      = "db-02"
  allow_stopping_for_update = true
  platform_id               = "standard-v2"
  zone                      = "ru-central1-a"

  resources {
    cores         = 4
    memory        = 8
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd8un8f40qgmlenpa0qb"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.bingo-subnet-a.id}"
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.user_name}:${file("~/.ssh/id_rsa.pub")}"
  }
}

