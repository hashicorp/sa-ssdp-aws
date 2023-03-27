# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "asg_name" {
  value = module.vm.asg_name
}

output "kms_key_arn" {
  value = module.kms.kms_key_arn
}

output "aws_vault_iam_role_arn" {
  value = module.iam.aws_vault_iam_role_arn
}

output "launch_template_id" {
  value = module.vm.launch_template_id
}

output "vault_lb_dns_name" {
  description = "DNS name of Vault load balancer"
  value       = module.loadbalancer.vault_lb_dns_name
}

output "vault_cluster_addr" {
  description = "DNS name of Vault load balancer"
  value       = "https://${module.loadbalancer.vault_lb_dns_name}:8200"
}

output "vault_lb_zone_id" {
  description = "Zone ID of Vault load balancer"
  value       = module.loadbalancer.vault_lb_zone_id
}

output "vault_lb_arn" {
  description = "ARN of Vault load balancer"
  value       = module.loadbalancer.vault_lb_arn
}

output "vault_target_group_arn" {
  description = "Target group ARN to register Vault nodes with"
  value       = module.loadbalancer.vault_target_group_arn
}

output "vault_sg_id" {
  description = "Security group ID of Vault cluster"
  value       = module.vm.vault_sg_id
}

output "cert_pem" {
  description = "CA for vault server cert verification"
  value     = module.aws_secrets.cert_pem
}
