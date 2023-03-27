# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "aws_iam_instance_profile" {
  value = aws_iam_instance_profile.vault.name
}

output "aws_vault_iam_role_arn" {
  value = aws_iam_role.instance_role[0].arn
}