output "aws_consul_iam_role_arn" {
  value = aws_iam_role.instance_role[0].arn
}

output "aws_iam_instance_profile" {
  value = aws_iam_instance_profile.consul.name
}
