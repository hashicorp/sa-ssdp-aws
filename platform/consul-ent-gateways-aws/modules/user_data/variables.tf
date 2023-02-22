variable "aws_region" {
  type        = string
  description = "AWS region where Vault is being deployed"
}

variable "resource_name_prefix" {
  type        = string
  description = "Resource name prefix used for tagging and naming AWS resources"
}

variable "consul_license_secret_path" {
  type        = string
  description = "Name of Vault Secret storing Consul license file"
}

variable "consul_version" {
  type        = string
  description = "Consul version"
}

variable "consul_dc" {
  type        = string
  default     = "dc1"
}

variable "consul_ca_token" {
  type        = string
  default     = null
}

variable "vault_version" {
  type        = string
  description = "Vault version"
}

variable "node_count" {
  type        = number
  description = "Number of Consul nodes to deploy in ASG"
}

variable "vault_ca" {
  type        = string
  default     = null
  description = "Vault CA"
}

variable "vault_addr" {
  type        = string
  default     = null
  description = "Vault Cluster Address"
}
