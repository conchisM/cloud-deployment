resource "null_resource" "ansible_provisioner_node_01" {
  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "sudo hostnamectl set-hostname node01"]

    connection {
      host        = yandex_compute_instance_group.bingo-group1.instances[0].network_interface[0].nat_ip_address
      type        = "ssh"
      user        = "${var.user_name}"
      private_key = "${file("~/.ssh/id_rsa")}"
      agent       = false
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${yandex_compute_instance_group.bingo-group1.instances[0].network_interface[0].nat_ip_address},'  ../node-playbook.yaml"
  }
}


resource "null_resource" "ansible_provisioner_node_02" {
  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "sudo hostnamectl set-hostname node02"]

    connection {
      host        = yandex_compute_instance_group.bingo-group1.instances[1].network_interface[0].nat_ip_address
      type        = "ssh"
      user        = "${var.user_name}"
      private_key = "${file("~/.ssh/id_rsa")}"
      agent       = false
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${yandex_compute_instance_group.bingo-group1.instances[1].network_interface[0].nat_ip_address},'  ../node-playbook.yaml"
  }
}

