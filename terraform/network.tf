resource "yandex_vpc_network" "bingo-network" {
  name = "bingo-network"
}

resource "yandex_vpc_subnet" "bingo-subnet-a" {
  name = "bingo-subnet-a"
  v4_cidr_blocks = ["10.2.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.bingo-network.id}"
}

resource "yandex_vpc_subnet" "bingo-subnet-b" {
  name = "bingo-subnet-b"
  v4_cidr_blocks = ["10.3.0.0/16"]
  zone           = "ru-central1-b"
  network_id     = "${yandex_vpc_network.bingo-network.id}"
}
