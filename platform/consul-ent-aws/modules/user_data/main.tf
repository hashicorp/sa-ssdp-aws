# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

locals {
  consul_user_data = templatefile(
    "${path.module}/templates/install_consul.sh.tpl",
    {
      region                      = var.aws_region
      name                        = var.resource_name_prefix
      consul_version              = var.consul_version
      consul_dc                   = var.consul_dc
      consul_ca_token             = var.consul_ca_token
      bootstrap_expect            = var.node_count
      consul_license_secret_path  = var.consul_license_secret_path
      vault_version               = var.vault_version
      vault_ca                    = file(var.vault_ca)
      vault_addr                  = var.vault_addr
    }
  )
}
