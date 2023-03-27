# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

// Pin the versions

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.21.0"
    }
    consul = {
      source = "hashicorp/consul"
      version = "~> 2.15.1"
    }
  }
}

provider "aws" {
  region = var.region
}

// Configure the providers

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
