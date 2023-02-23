# Do we have any??

output "mesh_gateway_asg_id" {
  description = "Name of the AWS Auto-Scale Group serving the Consul Gateway"
  value = module.vm.asg_name
}

output "aws_consul_gw_iam_role_arn" {
  value = module.iam.aws_consul_iam_role_arn
}