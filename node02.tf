resource "yandex_compute_instance" "node-02" {

  name                      = "node-02"
  allow_stopping_for_update = true
  platform_id               = "standard-v2"
  zone                      = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
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

resource "null_resource" "ansible_provisioner_node_02" {
  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host        = yandex_compute_instance.node-02.network_interface.0.nat_ip_address
      type        = "ssh"
      user        = "${var.user_name}"
      private_key = "${file("~/.ssh/id_rsa")}"
      agent       = false
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${yandex_compute_instance.node-02.network_interface.0.nat_ip_address},' ../node-playbook.yaml"
  }
}
