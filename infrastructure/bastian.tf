resource "tls_private_key" "this" {
  algorithm = "RSA"
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  version = "1.0.1"
  key_name   = "bastian-key"
  public_key = tls_private_key.this.public_key_openssh
}

data "template_file" "aws_bastian_init" {
  template = file("${path.module}/templates/bastian-setup.sh")
  vars = {
    consul_version = var.consul_version
    vault_version = var.vault_version
    sa_release_version = var.sa_release_version 
  }
}

resource "aws_instance" "bastian_platsvcs" {
  instance_type               = "t3.small"
  ami                         = data.aws_ami.ubuntu.id
  key_name                    = module.key_pair.key_pair_key_name
  vpc_security_group_ids      = [ aws_security_group.bastian_ingress.id ]
  subnet_id                   = module.vpc_platform_services.public_subnets[0]
  associate_public_ip_address = true
  user_data                   = data.template_file.aws_bastian_init.rendered
  tags = {
    Name = "bastian"
  }

  # Ensure cloud-init has finished executing before returning output
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.this.private_key_pem
      host        = aws_instance.bastian_platsvcs.public_dns      
    }
  }

}

resource "local_sensitive_file" "bastian_key" {
  content = tls_private_key.this.private_key_pem
  filename = "../inputs/bastian-key.pem"
  file_permission = 0400
  depends_on = [aws_instance.bastian_platsvcs]
}

resource "aws_security_group" "bastian_ingress" {
  name   = "bastian_ingress"
  vpc_id = module.vpc_platform_services.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "${local.ifconfig_co_json.ip}/32" ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
