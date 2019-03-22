provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_instance" "vault" {
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  count                       = "${var.vault_count}"
  private_ip                  = "172.31.16.${count.index + 31}"
  subnet_id                   = "${var.subnet}"

  tags {
    Name   = "vault-0${count.index + 1}"
    vault = "app"
  }

  connection {
    user        = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "file" {
    source      = "scripts/start_vault.sh"
    destination = "/tmp/start_vault.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /tmp/start_vault.sh",
    ]
  }
}

output "public_dns_vault" {
  value = "${aws_instance.vault.*.public_dns}"
}
