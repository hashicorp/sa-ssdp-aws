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
  iam_instance_profile        = aws_iam_instance_profile.bastian.name
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

# creates new instance role profile (noted by name_prefix which forces new resource) for named instance role
# uses random UUID & suffix
# see: https://www.terraform.io/docs/providers/aws/r/iam_instance_profile.html
resource "aws_iam_instance_profile" "bastian" {
  name_prefix = "${var.resource_name_prefix}-bastian"
  role        = aws_iam_role.instance_role.name
}

# creates IAM role for instances using supplied policy from data source below
resource "aws_iam_role" "instance_role" {
  name_prefix        = "${var.resource_name_prefix}-bastian"
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}

# defines JSON for instance role base IAM policy
data "aws_iam_policy_document" "instance_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "session_manager" {
  name   = "${var.resource_name_prefix}-bastian-ssm"
  role   = aws_iam_role.instance_role.id
  policy = data.aws_iam_policy_document.session_manager.json
}

data "aws_iam_policy_document" "session_manager" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    resources = [
      "*",
    ]
  }
}