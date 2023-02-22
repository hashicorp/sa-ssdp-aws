private_subnet_ids      = ${instance_subnets}
vpc_id                  = "${vpc_platform_services_id}"
region                  = "${region}"
allowed_inbound_cidrs   = ${vpc_cidr_blocks}
