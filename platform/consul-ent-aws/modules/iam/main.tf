# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# creates new instance role profile (noted by name_prefix which forces new resource) for named instance role
# uses random UUID & suffix
# see: https://www.terraform.io/docs/providers/aws/r/iam_instance_profile.html
resource "aws_iam_instance_profile" "consul" {
  name_prefix = "${var.resource_name_prefix}-consul"
  role        = var.user_supplied_iam_role_name != null ? var.user_supplied_iam_role_name : aws_iam_role.instance_role[0].name
}

# creates IAM role for instances using supplied policy from data source below
resource "aws_iam_role" "instance_role" {
  count                = var.user_supplied_iam_role_name != null ? 0 : 1
  name_prefix        = "${var.resource_name_prefix}-consul"
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

# creates IAM role policy for cluster discovery and attaches it to instance role
resource "aws_iam_role_policy" "cloud_auto_join" {
  count  = var.user_supplied_iam_role_name != null ? 0 : 1
  name   = "${var.resource_name_prefix}-consul-auto-join"
  role   = aws_iam_role.instance_role[0].id
  policy = data.aws_iam_policy_document.cloud_auto_join.json
}

# creates IAM policy document for linking to above policy as JSON
data "aws_iam_policy_document" "cloud_auto_join" {
  # allow role with this policy to do the following: list instances, list tags, autoscale
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "autoscaling:CompleteLifecycleAction",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "session_manager" {
  count  = var.user_supplied_iam_role_name != null ? 0 : 1
  name   = "${var.resource_name_prefix}-consul-ssm"
  role   = aws_iam_role.instance_role[0].id
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