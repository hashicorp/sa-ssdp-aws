
data "aws_region" "current" {}

module "iam" {
  source = "./modules/iam"

  resource_name_prefix         = var.resource_name_prefix

}

module "user_data" {
  source = "./modules/user_data"

  aws_region                  = var.region
  node_count                  = var.node_count
  resource_name_prefix        = var.resource_name_prefix
  consul_license_secret_path  = var.consul_license_secret_path
  consul_version              = var.consul_version
  consul_dc                   = var.region
  consul_partition            = var.consul_partition
  gateway_type                = var.gateway_type
  vault_version               = var.vault_version
  vault_addr                  = var.vault_addr
  vault_ca                    = var.vault_ca
}

module "vm" {
  source = "./modules/vm"

  allowed_inbound_cidrs       = var.allowed_inbound_cidrs_lb
  allowed_inbound_cidrs_ssh   = var.allowed_inbound_cidrs_ssh
  aws_iam_instance_profile    = module.iam.aws_iam_instance_profile
  instance_type               = var.instance_type
  node_count                  = var.node_count
  resource_name_prefix        = var.resource_name_prefix
  userdata_script             = module.user_data.consul_userdata_base64_encoded
  consul_subnets              = var.private_subnet_ids
  vpc_id                      = var.vpc_id
  gateway_type                = var.gateway_type
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