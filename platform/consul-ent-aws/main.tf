# module aim

data "aws_region" "current" {}

module "iam" {
  source = "./modules/iam"

  resource_name_prefix         = var.resource_name_prefix

}

# module user_data

module "user_data" {
  source = "./modules/user_data"

#  aws_bucket_vault_license    = module.object_storage.s3_bucket_vault_license
  # Get the license from Vault 
#  aws_region                  = data.aws_region.current.name
  aws_region                  = var.region
  node_count                = var.node_count
#  kms_key_arn                 = module.kms.kms_key_arn
#  leader_tls_servername       = module.aws_secrets.leader_tls_servername
  resource_name_prefix        = var.resource_name_prefix
#  secrets_manager_arn         = module.aws_secrets.secrets_manager_arn
#  user_supplied_userdata_path = var.user_supplied_userdata_path
  consul_license_secret_path  = var.consul_license_secret_path
  consul_version              = var.consul_version
  vault_version              = var.vault_version
  vault_token                 = var.vault_token
  vault_addr                  = var.vault_addr
  vault_ca                  = var.vault_ca
#  aws_vault_iam_role_arn    = var.aws_vault_iam_role_arn
}

# module vm


module "vm" {
  source = "./modules/vm"

  allowed_inbound_cidrs     = var.allowed_inbound_cidrs_lb
  allowed_inbound_cidrs_ssh = var.allowed_inbound_cidrs_ssh
  aws_iam_instance_profile  = module.iam.aws_iam_instance_profile
# common_tags               = var.common_tags
  instance_type             = var.instance_type
#  key_name                  = var.key_name
#  lb_type                   = var.lb_type
  node_count                = var.node_count
  resource_name_prefix      = var.resource_name_prefix
  userdata_script           = module.user_data.consul_userdata_base64_encoded
#  user_supplied_ami_id      = var.user_supplied_ami_id
 # vault_lb_sg_id            = module.loadbalancer.vault_lb_sg_id
  consul_subnets             = var.private_subnet_ids
 # vault_target_group_arns   = local.vault_target_group_arns
  vpc_id                    = var.vpc_id
}

