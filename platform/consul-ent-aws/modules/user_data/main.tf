/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

locals {
  consul_user_data = templatefile(
    var.user_supplied_userdata_path != null ? var.user_supplied_userdata_path : "${path.module}/templates/install_consul.sh.tpl",
    {
      region                  = var.aws_region
      name                    = var.resource_name_prefix
      consul_version           = var.consul_version
      datacenter  = "dc1"
      bootstrap_expect = var.node_count
      environment_name = "sa-ssdp"
#      kms_key_arn             = var.kms_key_arn
#      s3_bucket_vault_license = var.aws_bucket_vault_license
      consul_license_secret_path      = var.consul_license_secret_path
      gossip_key = "DVgIGdDx5G1JOoCIuZrRXxjXyfVY6yrI/riRPbnTllw="  //TODO: this needs to come from Vault Cluster
      vault_version     = var.vault_version
      vault_ca     = file("${path.module}/${var.vault_ca}") # From Vault Module output.
      vault_addr   = var.vault_addr
      vault_token  = var.vault_token
#      leader_tls_servername   = var.leader_tls_servername
    }
  )
}
