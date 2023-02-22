/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

data "aws_ami" "ubuntu" {
  count       = var.user_supplied_ami_id != null ? 0 : 1
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "consul_gw" {
  name   = "${var.resource_name_prefix}-consul-gw"
  vpc_id = var.vpc_id

  tags = merge(
    { Name = "${var.resource_name_prefix}-consul-gw-sg" },
    var.common_tags,
  )
}

resource "aws_security_group_rule" "consul_gw_internal_rpc" {
  description       = "Allow Consul nodes to reach other on port 8300 for API"
  security_group_id = aws_security_group.consul_gw.id
  type              = "ingress"
  from_port         = 8300
  to_port           = 8300
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "consul_gw_internal_lan_serf_tcp" {
  description       = "Allow Consul nodes to communicate on port 8301 & 8302 for replication traffic, request forwarding, and Raft gossip"
  security_group_id = aws_security_group.consul_gw.id
  type              = "ingress"
  from_port         = 8301
  to_port           = 8302
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "consul_internal_lan_serf_udp" {
  description       = "Allow Consul nodes to communicate on port 8201 for replication traffic, request forwarding, and Raft gossip"
  security_group_id = aws_security_group.consul_gw.id
  type              = "ingress"
  from_port         = 8301
  to_port           = 8302
  protocol          = "udp"
  self              = true
}

# The following data source gets used if the user has
# specified a network load balancer.
# This will lock down the EC2 instance security group to
# just the subnets that the load balancer spans
# (which are the private subnets the Vault instances use)

data "aws_subnet" "subnet" {
  count = length(var.consul_subnets)
  id    = var.consul_subnets[count.index]
}

locals {
  subnet_cidr_blocks = [for s in data.aws_subnet.subnet : s.cidr_block]
}


## Required for AWS SSM sessions
resource "aws_security_group_rule" "consul_gw_lan_serf_tcp_inbound" {
  count             = var.allowed_inbound_cidrs != null ? 1 : 0
  description       = "Allow specified CIDRs SSH access to Consul nodes"
  security_group_id = aws_security_group.consul_gw.id
  type              = "ingress"
  from_port         = 8300
  to_port           = 8302
  protocol          = "tcp"
  cidr_blocks       = var.allowed_inbound_cidrs
}

resource "aws_security_group_rule" "consul_gw_lan_serf_udp_inbound" {
  count             = var.allowed_inbound_cidrs != null ? 1 : 0
  description       = "Allow specified CIDRs SSH access to Consul nodes"
  security_group_id = aws_security_group.consul_gw.id
  type              = "ingress"
  from_port         = 8300
  to_port           = 8302
  protocol          = "udp"
  cidr_blocks       = var.allowed_inbound_cidrs
}

resource "aws_security_group_rule" "consul_gw_api_inbound" {
  count             = var.allowed_inbound_cidrs != null ? 1 : 0
  description       = "Allow specified CIDRs to Consul HTTP API"
  security_group_id = aws_security_group.consul_gw.id
  type              = "ingress"
  from_port         = 8500
  to_port           = 8501
  protocol          = "tcp"
  cidr_blocks       = var.allowed_inbound_cidrs
}

resource "aws_security_group_rule" "consul_grpc_inbound" {
  count             = var.allowed_inbound_cidrs != null ? 1 : 0
  description       = "Allow specified CIDRs to Consul gRPC"
  security_group_id = aws_security_group.consul_gw.id
  type              = "ingress"
  from_port         = 8502
  to_port           = 8503
  protocol          = "tcp"
  cidr_blocks       = var.allowed_inbound_cidrs
}


## Required for AWS SSM sessions
resource "aws_security_group_rule" "consul_gw_ssh_inbound" {
  count             = var.allowed_inbound_cidrs_ssh != null ? 1 : 0
  description       = "Allow specified CIDRs SSH access to Consul nodes"
  security_group_id = aws_security_group.consul_gw.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_inbound_cidrs_ssh
}

resource "aws_security_group_rule" "consul_outbound" {
  description       = "Allow Vault nodes to send outbound traffic"
  security_group_id = aws_security_group.consul_gw.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_launch_template" "consul_gw" {
  name          = "${var.resource_name_prefix}-consul-gw"
  image_id      = var.user_supplied_ami_id != null ? var.user_supplied_ami_id : data.aws_ami.ubuntu[0].id
  instance_type = var.instance_type
  key_name      = var.key_name != null ? var.key_name : null
  user_data     = var.userdata_script
  vpc_security_group_ids = [
    aws_security_group.consul_gw.id,
  ]

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = "gp3"
      volume_size           = 100
      throughput            = 150
      iops                  = 3000
      delete_on_termination = true
    }
  }

  iam_instance_profile {
    name = var.aws_iam_instance_profile
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_autoscaling_group" "consul_gw" {
  name                = "${var.resource_name_prefix}-consul-gw"
  min_size            = var.node_count
  max_size            = var.node_count
  desired_capacity    = var.node_count
  vpc_zone_identifier = var.consul_subnets
#  target_group_arns   = var.consul_target_group_arns

  launch_template {
    id      = aws_launch_template.consul_gw.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.resource_name_prefix}-consul-gateway"
    propagate_at_launch = true
  }

  tag {
    key                 = "${var.resource_name_prefix}-consul-gw"
    value               = "gateway"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.common_tags
    content {
      key   = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
}
