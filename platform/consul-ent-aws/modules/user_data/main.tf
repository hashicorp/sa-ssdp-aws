locals {
  consul_user_data = templatefile(
    var.user_supplied_userdata_path != null ? var.user_supplied_userdata_path : "${path.module}/templates/install_consul.sh.tpl",
    {
      region                     = var.aws_region
      name                       = var.resource_name_prefix
      consul_version             = var.consul_version
      datacenter                 = var. consul_dc
      bootstrap_expect           = var.node_count
      consul_license_secret_path = var.consul_license_secret_path
      vault_version              = var.vault_version
      vault_ca                   = file(var.vault_ca)
      vault_addr                 = var.vault_addr
    }
  )
}
