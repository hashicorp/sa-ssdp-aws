
output "asg_name" {
  description = "Name of the AWS Auto-Scale Group serving the Consul Cluster"
  value = module.vm.asg_name
}
