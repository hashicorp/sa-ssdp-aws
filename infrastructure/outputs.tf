output "your_ip_addr" {
  value = local.ifconfig_co_json.ip
}

#output "vpc_platform_services_all" {
#  value = module.vpc_platform_services.vpc_all
#}

output "vpc_platform_services_id" {
  value = module.vpc_platform_services.vpc_id
}

output "vpc_platform_services_public_subnets" {
  value = module.vpc_platform_services.public_subnets
}

output "vpc_app_microservices_id" {
  value = module.vpc_app_microservices.vpc_id
}

output "vpc_payments" {
  value = module.vpc_payments.vpc_id
}

output "app_eks_cluster" {
  value = module.eks.cluster_id
}

output "bastian_platsvcs" {
  value = "ssh -o 'IdentitiesOnly yes' -i '../inputs/bastian-key.pem' ubuntu@${aws_instance.bastian_platsvcs.public_dns}"
}

output "bastian_platsvcs_copy_licenses" {
  value = "scp -o 'IdentitiesOnly yes' -i '../inputs/bastian-key.pem' ../inputs/*.hclic ubuntu@${aws_instance.bastian_platsvcs.public_dns}:/home/ubuntu/sa-ssp-aws/inputs/"
}


#output "bastian_app_vpc" {
#  value = "ssh -o 'IdentitiesOnly yes' -i '../keys/app_vpc.pem' ubuntu@${aws_instance.bastian.public_dns}"
#}


#output "hcp_consul_public_endpoint_url" {
#  value = "${hcp_consul_cluster.hcp_consul.consul_public_endpoint_url}"
#}
#
#output "hcp_consul_acl_token_secret_id" {
#  value = hcp_consul_cluster_root_token.token.secret_id
#  sensitive = true
#}
#
#output "vault_cluster_host" {
#  value = hcp_vault_cluster.hcp_vault.vault_public_endpoint_url
#}
#
#output "vault_cluster_host_private" {
#  value = hcp_vault_cluster.hcp_vault.vault_private_endpoint_url
#}
#
#output "vault_admin_token" {
#  value = hcp_vault_cluster_admin_token.user.token
#  sensitive = true
#}
#
#output "eks_prod_cluster_id" {
#  value = module.hcp_eks_prod.eks_prod_cluster_id
#}
#
#output "eks_dev_cluster_id" {
#  value = module.hcp_eks_dev.eks_dev_cluster_id
#}
#
#output "unique_deployment_id" {
#  value = random_string.rand_suffix.result
#}
#
#output "ecs_dev_hashicups_url" {
#  value = module.hcp_ecs_dev.client_lb_address
#}

#output "bastian_vpc_platform_services_connect" {
#  value = "ssh -o 'IdentitiesOnly yes' -i '../keys/eks-prod_bastian.pem' ubuntu@${module.hcp_eks_prod.bastian_addr}"
#}
#
#output "bastian_vpc_app_microservices_connect" {
#  value = "ssh -o 'IdentitiesOnly yes' -i '../keys/eks-dev_bastian.pem' ubuntu@${module.hcp_eks_dev.bastian_addr}"
#}
#
#output "bastian_vpc_payments_database_connect" {
#  value = "ssh -o 'IdentitiesOnly yes' -i '../keys/ecs-dev_bastian.pem' ubuntu@${module.hcp_ecs_dev.bastian_addr}"
#}
