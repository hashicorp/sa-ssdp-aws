# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


# Create VPC Peering Connections

resource "aws_vpc_peering_connection" "vpc_platform_services_2_vpc_app_microservices" {
  vpc_id        = module.vpc_platform_services.vpc_id
  peer_owner_id = module.vpc_app_microservices.vpc_owner_id
  peer_vpc_id   = module.vpc_app_microservices.vpc_id
  auto_accept   = true
}

resource "aws_vpc_peering_connection" "vpc_platform_services_2_vpc_payments" {
  vpc_id        = module.vpc_platform_services.vpc_id
  peer_owner_id = module.vpc_payments.vpc_owner_id
  peer_vpc_id   = module.vpc_payments.vpc_id
  auto_accept   = true
}

resource "aws_vpc_peering_connection" "vpc_app_microservices_2_vpc_payments" {
  vpc_id        = module.vpc_app_microservices.vpc_id
  peer_owner_id = module.vpc_payments.vpc_owner_id
  peer_vpc_id   = module.vpc_payments.vpc_id
  auto_accept   = true
}


# Create Routes For VPC Peering Connections

locals {
  vpc_platform_services_routes = concat(module.vpc_platform_services.private_route_table_ids,module.vpc_platform_services.public_route_table_ids)
  vpc_app_microservices_routes = concat(module.vpc_app_microservices.private_route_table_ids,module.vpc_app_microservices.public_route_table_ids)
  vpc_payments_routes = concat(module.vpc_payments.private_route_table_ids,module.vpc_payments.public_route_table_ids)
}

resource "aws_route" "vpc_platform_services_2_vpc_app_microservices" {
  count                     = length(local.vpc_platform_services_routes)
  route_table_id            = local.vpc_platform_services_routes[count.index]
  destination_cidr_block    = module.vpc_app_microservices.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_platform_services_2_vpc_app_microservices.id
}

resource "aws_route" "vpc_app_microservices_2_vpc_platform_services" {
  count                     = length(local.vpc_app_microservices_routes)
  route_table_id            = local.vpc_app_microservices_routes[count.index]
  destination_cidr_block    = module.vpc_platform_services.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_platform_services_2_vpc_app_microservices.id
}

resource "aws_route" "vpc_platform_services_2_vpc_payments" {
  count                     = length(local.vpc_platform_services_routes)
  route_table_id            = local.vpc_platform_services_routes[count.index]
  destination_cidr_block    = module.vpc_payments.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_platform_services_2_vpc_payments.id
}

resource "aws_route" "vpc_payments_2_vpc_platform_services" {
  count                     = length(local.vpc_payments_routes)
  route_table_id            = local.vpc_payments_routes[count.index]
  destination_cidr_block    = module.vpc_platform_services.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_platform_services_2_vpc_payments.id
}

resource "aws_route" "vpc_app_microservices_2_vpc_payments" {
  count                     = length(local.vpc_app_microservices_routes)
  route_table_id            = local.vpc_app_microservices_routes[count.index]
  destination_cidr_block    = module.vpc_payments.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_app_microservices_2_vpc_payments.id
}

resource "aws_route" "vpc_payments_2_vpc_app_microservices" {
  count                     = length(local.vpc_payments_routes)
  route_table_id            = local.vpc_payments_routes[count.index]
  destination_cidr_block    = module.vpc_app_microservices.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_app_microservices_2_vpc_payments.id
}
