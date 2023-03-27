# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "kms_key_arn" {
  value = var.user_supplied_kms_key_arn != null ? var.user_supplied_kms_key_arn : aws_kms_key.vault[0].arn
}
