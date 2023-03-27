# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data "aws_vpc" "selected" {
  id = var.vpc_id
}
