# Create VPCs

module "vpc" {
  source   = "terraform-aws-modules/vpc/aws"
#  version  = "3.11.0"
  version  = "3.18.1"
  name = var.name
  cidr = var.cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway      = true
  single_nat_gateway      = true
  enable_dns_hostnames    = true
  
  tags = var.tags
}
