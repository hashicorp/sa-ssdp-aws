# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "vault_userdata_base64_encoded" {
  value = base64encode(local.vault_user_data)
}
