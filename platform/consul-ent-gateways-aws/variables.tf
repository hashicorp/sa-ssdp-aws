variable "region" {
  description = "Default AWS Region to deploy in."
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where Vault will be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs to deploy Consul Gateway into"
}

variable "gateway_type" {
  type        = string
  description = "Type of Consul Gateway: mesh, ingress, terminating"
  validation {
    condition     = var.gateway_type == "mesh" || var.gateway_type == "ingress" || var.gateway_type == "terminating"
    error_message = "You must specify one of the following gateway types: mesh, ingress, terminating"
  }
}

variable "node_count" {
  type        = number
  description = "Number of Consul Gateway nodes to deploy in ASG"
  default     = 2
}

variable "instance_type" {
  type        = string
  default     = "m5.large"
  description = "EC2 instance type"
}

variable "allowed_inbound_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks to permit inbound traffic from to load balancer"
  default     = null
}

variable "allowed_inbound_cidrs_lb" {
  type        = list(string)
  description = "(Optional) List of CIDR blocks to permit inbound traffic from to load balancer"
  default     = null
}

variable "allowed_inbound_cidrs_ssh" {
  type        = list(string)
  description = "List of CIDR blocks to give SSH access to Vault nodes"
  default     = null
}

variable "consul_version" {
  type        = string
  default     = "1.12.8"
  description = "Consul version"
}

variable "consul_license_secret_path" {
  type        = string
  description = "Name of Vault Secret storing Consul license file"
  default     = "consul/secret/enterpriselicense"
}

variable "consul_partition" {
  type        = string
  default     = null
  description = "Consul Administrative Partition for which the Consul Gateway serves"
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

variable "vault_addr" {
  type        = string
  default     = null
  description = "Vault Cluster Address"
}

variable "resource_name_prefix" {
  type        = string
  description = "Resource name prefix used for tagging and naming AWS resources"
  default     = "sa"
}
