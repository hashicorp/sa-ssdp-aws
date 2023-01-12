# If NOT Platform Services VPC, peer to Platform Services VPC

#resource "aws_vpc_peering_connection_accepter" "peering_acceptor" {
#  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
#  auto_accept               = true
#}


# Routes for peering

#locals {
#  route_table_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
#  route_table_ids = concat(module.vpc.private_route_table_ids)
#}

#resource "aws_route" "vpc_to_hvn" {
#  count                     = length(local.route_table_ids)
#  route_table_id            = local.route_table_ids[count.index]
#  destination_cidr_block    = var.hvn_cidr_block
#  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
#}