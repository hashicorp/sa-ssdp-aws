# Copyright IBM Corp. 2022, 2026

output "consul_userdata_base64_encoded" {
  value = base64encode(local.consul_user_data)
}
