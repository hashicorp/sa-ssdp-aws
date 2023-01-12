#output "services_vpc_all" {
#  value = data.aws_vpc.selected
#}

output "services_vpc_arn" {
  value = data.aws_vpc.selected.arn
}

output "consul_cluster_add" {
  value = module.servers.mesh_gateway_addr
}