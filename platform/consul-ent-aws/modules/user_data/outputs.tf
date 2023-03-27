# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "consul_userdata_base64_encoded" {
  value = base64encode(local.consul_user_data)
}
