# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

variable "project" {
  default = "18cld"
}

data "aws_vpc" "vpc" {
  tags {
    Name = "${var.project}"
  }
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags {
    Tier = "Public"
  }
}

data "aws_subnet" "public" {
  count = "${length(data.aws_subnet_ids.all.ids)}"
  id    = "${data.aws_subnet_ids.all.ids[count.index]}"
}

resource "random_shuffle" "random_subnet" {
  input        = ["${data.aws_subnet.public.*.id}"]
  result_count = 1
}

resource "aws_instance" "managers" {
  instance_type = "t2.micro"
  ami           = "${lookup(var.aws_amis, var.aws_region)}"

  count = 1

  subnet_id              = "${random_shuffle.random_subnet.result[0]}"
  vpc_security_group_ids = ["${aws_security_group.allow-internal-swarm.id}"]
  key_name               = "${var.KEY_NAME}"

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "file" {
    source      = "script-init-swarm.sh"
    destination = "/tmp/script-init-swarm.sh"
  }

  provisioner "file" {
    source      = "../compose.yml"
    destination = "/tmp/compose.yml"
  }

  provisioner "file" {
    source      = "../Dockerfile"
    destination = "/tmp/Dockerfile"
  }

  provisioner "file" {
    source      = "../prometheus.yml"
    destination = "/tmp/prometheus.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sudo /tmp/script.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script-init-swarm.sh",
      "sudo /tmp/script-init-swarm.sh",
    ]
  }

  connection {
    user        = "${var.INSTANCE_USERNAME}"
    private_key = "${file("${var.PATH_TO_KEY}")}"
  }

  tags {
    Name = "${format("manager-%03d", count.index + 1)}"
  }
}

resource "aws_instance" "workers" {
  instance_type = "t2.micro"
  ami           = "${lookup(var.aws_amis, var.aws_region)}"

  count = 2

  subnet_id              = "${random_shuffle.random_subnet.result[0]}"
  vpc_security_group_ids = ["${aws_security_group.allow-internal-swarm.id}"]
  key_name               = "${var.KEY_NAME}"

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sudo /tmp/script.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo docker swarm join ${aws_instance.managers.0.private_ip}:2377 --token $(docker -H ${aws_instance.managers.0.private_ip} swarm join-token -q worker)",
    ]
  }

  connection {
    user        = "${var.INSTANCE_USERNAME}"
    private_key = "${file("${var.PATH_TO_KEY}")}"
  }

  tags {
    Name = "${format("worker-%03d", count.index + 1)}"
  }

  depends_on = [
    "aws_instance.managers",
  ]
}
