output "your_ip_addr" {
  value = local.ifconfig_co_json.ip
}


## Platform Services VPC output

output "vpc_platform_services_id" {
  value = module.vpc_platform_services.vpc_id
}

output "vpc_platform_services_private_subnets" {
  value = module.vpc_platform_services.private_subnets
}


## App Microservices VPC output

output "vpc_app_microservices_id" {
  value = module.vpc_app_microservices.vpc_id
}

output "vpc_app_microservices_private_subnets" {
  value = module.vpc_app_microservices.private_subnets
}

output "app_eks_cluster" {
  value = module.eks.cluster_id
}

output "app_eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}


## Payments VPC output

output "vpc_payments_id" {
  value = module.vpc_payments.vpc_id
}

output "vpc_payments_private_subnets" {
  value = module.vpc_payments.private_subnets
}


## Bastian Host - Operator Stuff

output "bastian_platsvcs" {
  value = "ssh -o 'IdentitiesOnly yes' -i '../inputs/bastian-key.pem' ubuntu@${aws_instance.bastian_platsvcs.public_dns}"
}

output "bastian_platsvcs_copy_licenses" {
  value = "scp -o 'IdentitiesOnly yes' -i '../inputs/bastian-key.pem' ../inputs/* ubuntu@${aws_instance.bastian_platsvcs.public_dns}:/home/ubuntu/sa-ssdp-aws/inputs/"
}
