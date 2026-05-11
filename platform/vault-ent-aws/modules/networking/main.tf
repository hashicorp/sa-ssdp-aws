# Copyright IBM Corp. 2022, 2026

data "aws_vpc" "selected" {
  id = var.vpc_id
}
