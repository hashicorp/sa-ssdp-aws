# Util

resource "random_string" "rand_suffix" {
  length  = 6
  special = false
  lower   = true
  upper   = false
}


# VPC Deployments

## Platform Services VPC
module "vpc_platform_services" {
  source = "./modules/vpc"

  region             = var.region
  name               = var.env_platform_services.name
  suffix             = random_string.rand_suffix.result
  availability_zones = var.availability_zones
  cidr               = var.env_platform_services.cidr
  private_subnets    = var.env_platform_services.private_subnets
  public_subnets     = var.env_platform_services.public_subnets

  tags = {
    Terraform   = "true"
    Environment = var.env_platform_services.name
  }

}

## Front-end & API Microservice EKS VPC
module "vpc_app_microservices" {
  source = "./modules/vpc"

  region             = var.region
  name               = var.env_app_microservices.name
  cidr               = var.env_app_microservices.cidr
  suffix             = random_string.rand_suffix.result
  availability_zones = var.availability_zones
  private_subnets    = var.env_app_microservices.private_subnets
  public_subnets     = var.env_app_microservices.public_subnets

  tags = {
    Terraform   = "true"
    Environment = var.env_app_microservices.name
  }

}

## Payments VM EC2 VPC
module "vpc_payments" {
  source = "./modules/vpc"

  region             = var.region
  name               = var.env_payments.name
  cidr               = var.env_payments.cidr
  suffix             = random_string.rand_suffix.result
  availability_zones = var.availability_zones
  private_subnets    = var.env_payments.private_subnets
  public_subnets     = var.env_payments.public_subnets

  tags = {
    Terraform   = "true"
    Environment = var.env_payments.name
  }

}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.20.0"

#  cluster_name             = var.cluster_name
  cluster_name             = "${var.env_app_microservices.name}-eks"
  cluster_version          = "1.22"   # https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
#  subnets                  = var.private_subnets
#  subnets                  = module.vpc_app_microservices.public_subnets
  subnets                  = module.vpc_app_microservices.private_subnets
#  vpc_id                   = var.vpc_id
  vpc_id                   = module.vpc_app_microservices.vpc_id
  write_kubeconfig         = false

  node_groups = {
    application = {
      name_prefix      = "hashicups"
      instance_types   = ["t3a.large"]
      desired_capacity = 3
      max_capacity     = 3
      min_capacity     = 3
    }
  }
}


# EC2 Module Deployments

