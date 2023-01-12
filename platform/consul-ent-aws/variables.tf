variable "AWS_ACCESS_KEY_ID" {
  type = string
  default = ""
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
  default = ""
}

variable "region" {
  description = "Default AWS Region to deploy in."
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "env_name" {
  type    = string
  default = ""  
}

variable "eks_cluster_name" {
  type    = string
  default = ""
}

variable "key_name" {
  type    = string
  default = ""
}

variable "instance_subnets" {
  type    = list
  default = []
}