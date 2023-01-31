variable "region" {
  description = "Default AWS Region to deploy in."
  type        = string
  default     = "us-west-2"
}

variable "consul_license_secret_path" {
  type        = string
  description = "Name of Vault Secret storing Consul license file"
  default     = "consul/secret/enterpriselicense"
}

variable "consul_version" {
  type        = string
  default     = "1.12.8"
  description = "Consul version"
}

variable "vault_version" {
  type        = string
  default     = "1.12.2"
  description = "Vault version"
}

variable "vault_ca" {
  type        = string
  default     = null
  description = "Vault CA"
}

variable "vault_token" {
  type        = string
  default     = null
  description = "Vault token"
}

variable "vault_addr" {
  type        = string
  default     = null
  description = "Vault Cluster Address"
}

variable "aws_vault_iam_role_arn" {
  type        = string
  default     = null
  description = "IAM Role ARN, for AWS Auto-Auth"
}

variable "resource_name_prefix" {
  type        = string
  description = "Resource name prefix used for tagging and naming AWS resources"
  default     = "sa"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where Vault will be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs to deploy Consul into"
}

variable "allowed_inbound_cidrs_lb" {
  type        = list(string)
  description = "(Optional) List of CIDR blocks to permit inbound traffic from to load balancer"
  default     = null
}

variable "allowed_inbound_cidrs_ssh" {
  type        = list(string)
  description = "(Optional) List of CIDR blocks to permit for SSH to Consul nodes"
  default     = null
}

variable "node_count" {
  type        = number
  default     = 5
  description = "Number of Vault nodes to deploy in ASG"
}

variable "instance_type" {
  type        = string
  default     = "m5.xlarge"
  description = "EC2 instance type"
}