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




# Create VPC Peering to HCP HVN

#resource "hcp_aws_network_peering" "peer" {
#  hvn_id          = var.hcp_hvn_id
#  peer_vpc_id     = module.vpc.vpc_id
#  peer_account_id = module.vpc.vpc_owner_id
#  peer_vpc_region = var.region
#  peering_id      = "${var.hcp_hvn_id}-${var.name}"
#}
#
#resource "aws_vpc_peering_connection_accepter" "peering_acceptor" {
#  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
#  auto_accept               = true
#}


# Create Routes to/from HVN

#resource "hcp_hvn_route" "hvn_to_vpc" {
#  hvn_link         = var.hcp_hvn_self_link
#  hvn_route_id     = "${var.hcp_hvn_id}-${var.name}"
#  destination_cidr = module.vpc.vpc_cidr_block
#  target_link      = hcp_aws_network_peering.peer.self_link
#}
#
#locals {
#  route_table_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
#}
#
#resource "aws_route" "vpc_to_hvn" {
#  count                     = length(local.route_table_ids)
#  route_table_id            = local.route_table_ids[count.index]
#  destination_cidr_block    = var.hvn_cidr_block
#  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
#}
