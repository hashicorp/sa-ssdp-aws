/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

locals {
  vault_user_data = templatefile(
    var.user_supplied_userdata_path != null ? var.user_supplied_userdata_path : "${path.module}/templates/install_vault.sh.tpl",
    {
      region                  = var.aws_region
      name                    = var.resource_name_prefix
      vault_version           = var.vault_version
      kms_key_arn             = var.kms_key_arn
      s3_bucket_vault_license = var.aws_bucket_vault_license
      vault_license_name      = var.vault_license_name
      secrets_manager_arn     = var.secrets_manager_arn
      leader_tls_servername   = var.leader_tls_servername
    }
  )
}
