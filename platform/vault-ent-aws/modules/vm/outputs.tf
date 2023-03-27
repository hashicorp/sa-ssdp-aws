# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "asg_name" {
  description = "Name of autoscaling group"
  value       = aws_autoscaling_group.vault.name
}

output "launch_template_id" {
  description = "ID of launch template for Vault autoscaling group"
  value       = aws_launch_template.vault.id
}

output "vault_sg_id" {
  description = "Security group ID of Vault cluster"
  value       = aws_security_group.vault.id
}
