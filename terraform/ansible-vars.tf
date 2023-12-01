resource "local_file" "ansible_vars_tf" {
  content  = <<-DOC
    user_name: ${var.user_name}
    ansible_python_interpreter: /usr/bin/python3
    node01_ip: ${yandex_compute_instance_group.bingo-group1.instances[0].network_interface[0].nat_ip_address}
    node02_ip: ${yandex_compute_instance_group.bingo-group1.instances[1].network_interface[0].nat_ip_address}
    db01_ip: ${yandex_compute_instance.db-01.network_interface.0.ip_address}
    pg_version: "12"
    db02_ip: ${yandex_compute_instance.db-02.network_interface.0.ip_address}
    user_name_db: ${var.user_name_db}
    user_pass_db: ${var.user_pass_db}
    DOC
  filename = "../vars/main.yaml" 
}
