# Copyright IBM Corp. 2022, 2026

output "vpc_id" {
  value = data.aws_vpc.selected.id
}
