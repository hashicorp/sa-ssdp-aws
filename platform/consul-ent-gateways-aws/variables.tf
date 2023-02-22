variable "region" {
  description = "Default AWS Region to deploy in."
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where Vault will be deployed"
}

