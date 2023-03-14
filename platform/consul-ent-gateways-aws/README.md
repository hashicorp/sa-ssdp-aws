# consul-ent-gateways-aws

Terraform Module for creating Consul Gateway Scale Groups on AWS.

Specity which VPC, and subnets to attach the Auto-Scale Groups to:

```hcl
region                   = "<aws-region>"
vpc_id                   = "<vpc-id>"
private_subnet_ids       = ["<subnet-id>","<subnet-id>","<subnet-id>"]

gateway_type		         = "<mesh|ingress|terminating>"
consul_partition         = "<partition_name>"
```
