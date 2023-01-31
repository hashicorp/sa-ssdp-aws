
output "asg_name" {
  description = "Name of the AWS Auto-Scale Group serving the Consul Cluster"
  value = module.vm.asg_name
}


output "aws_consul_iam_role_arn" {
  value = module.iam.aws_consul_iam_role_arn
}

output "aws_iam_instance_profile" {
  value = module.iam.aws_iam_instance_profile
}