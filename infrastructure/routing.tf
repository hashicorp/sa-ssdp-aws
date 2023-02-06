
# Create VPC Peering Connections

resource "aws_vpc_peering_connection" "vpc_platform_services_2_vpc_app_microservices" {
  vpc_id        = module.vpc_platform_services.vpc_id
  peer_owner_id = module.vpc_platform_services.vpc_owner_id
  peer_vpc_id   = module.vpc_app_microservices.vpc_id
  auto_accept   = true
}

resource "aws_vpc_peering_connection" "vpc_platform_services_2_vpc_payments" {
  vpc_id        = module.vpc_platform_services.vpc_id
  peer_owner_id = module.vpc_platform_services.vpc_owner_id
  peer_vpc_id   = module.vpc_payments.vpc_id
  auto_accept   = true
}

resource "aws_vpc_peering_connection" "vpc_app_microservices_2_vpc_payments" {
  vpc_id        = module.vpc_app_microservices.vpc_id
  peer_owner_id = module.vpc_app_microservices.vpc_owner_id
  peer_vpc_id   = module.vpc_payments.vpc_id
  auto_accept   = true
}


# Create Routes For VPC Peering Connections

#FIXME: Finish these routes for each of the three VPC Peerings above

resource "aws_route" "vpc_platform_services_2_vpc_app_microservices" {
  count                     = length(var.eks_dev_route_table_ids)
  route_table_id            = var.eks_dev_route_table_ids[count.index]
  destination_cidr_block    = var.ecs_dev_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.ecs_dev_to_eks_dev.id
}

resource "aws_route" "vpc_app_microservices_2_vpc_platform_services" {
  count                     = length(var.ecs_dev_route_table_ids)
  route_table_id            = var.ecs_dev_route_table_ids[count.index]
  destination_cidr_block    = var.eks_dev_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.ecs_dev_to_eks_dev.id
}

