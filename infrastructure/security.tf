locals {
  ingress_consul_rules = [
    {
      description = "Consul LAN Serf (tcp)"
      port        = 8301
      protocol    = "tcp"
    },
    {
      description = "Consul LAN Serf (udp)"
      port        = 8301
      protocol    = "udp"
    },
  ]

  eks_security_ids = [module.eks.cluster_primary_security_group_id]

  consul_security_groups = flatten([
    for _, sg in local.eks_security_ids : [
      for _, rule in local.ingress_consul_rules : {
        security_group_id = sg
        description       = rule.description
        port              = rule.port
        protocol          = rule.protocol
      }
    ]
  ])
}

resource "aws_security_group_rule" "consul_existing_grp" {
  count             = length(local.consul_security_groups)
  description       = local.consul_security_groups[count.index].description
  protocol          = local.consul_security_groups[count.index].protocol
  security_group_id = local.consul_security_groups[count.index].security_group_id
  cidr_blocks       = [var.hvn_cidr]
  from_port         = local.consul_security_groups[count.index].port
  to_port           = local.consul_security_groups[count.index].port
  type              = "ingress"
}
