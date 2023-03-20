# General

variable "region" {
  description = "Default AWS Region to deploy in."
  type        = string
  default     = ""
}

variable "name" {
  description = "VPC Name"
  type        = string
  default     = ""
}

variable "suffix" {
  description = "Random for resoure naming"
  type        = string
  default     = ""
}


# VPC

variable "availability_zones" {
  description = "AWS Availabily Zones"
  type        = list(string)
  default     = []
}

variable "cidr" {
  description = "VPC cidr"
  type        = string
  default     = ""
}

variable "private_subnets" {
  description = "VPC Private Subnets"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "VPC public Subnets"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "VPC tags"
  type        = map
  default     = {}
}

## For Bastian Security Group

variable "operator_source_ip" {
  description = "source IP Address for security groups"
  type = string
  default = ""
}
