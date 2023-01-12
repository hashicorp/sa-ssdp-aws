# Vault Enterprise AWS

module "servers" {
  source = "./accelerator-aws-consul/modules/immutable-aws-consul"

  # Instance Configuration
  ami_id              = "ami-0123456789abcdef0"
#  ami_id              =   data.aws_ami.ubuntu.id
  instance_type       = "m5.large"
#  key_name            = "user-key" # SSH key pair registered in AWS
#  key_name            =   module.key_pair.key_pair_key_name
  key_name            =   var.key_name
#  vpc_id              = "vpc-0270bfc41c9fc9aab"
  vpc_id              = var.vpc_id
#  instance_subnets    = ["subnet-aaaaaaaa", "subnet-bbbbbbbb", "subnet-cccccccc"] # Generally private (NAT) subnets
#  instance_subnets    = ["subnet-03892e82c90c63f9b", "subnet-039d54a3c5a188135", "subnet-03eaa80c2e9553a2c"]
  instance_subnets    = var.instance_subnets
  associate_public_ip = false
  attach_ssm_policy   = true

  # Cluster Details
  consul_cluster_version = "0.0.1"
  consul_nodes           = 5
  environment_name       = "primary" # Used for auto-join tagging
  tag_owner              = "someone@hashicorp.com"

  disk_params = {
    root = {
      volume_type = "gp3"
      volume_size = 32
      iops        = 3000
    },
    data = {
      volume_type = "gp3"
      volume_size = 100
      iops        = 3000
    }
  }

  consul_secrets = {
#    secrets_manager_arn = "arn:aws:secretsmanager:us-east-2:012345678901:secret:consul/server-config-abcdef"
    secrets_manager_arn = aws_secretsmanager_secret.consul_secrets.arn
#    kms_key_arn         = "arn:aws:kms:us-east-2:012345678901:key/00a00000-aa00-00aa-aa0a-00a00aaa000a"
    kms_key_arn         = aws_kms_key.consul_key.arn
  }

  consul_agent = {
    container_image    = "hashicorp/consul-enterprise:1.12.1-ent"
    server             = true
    datacenter         = "dc1"
    primary_datacenter = "dc1"
    ca_cert            = file("${path.module}/consul-agent-ca.pem")
    agent_cert         = file("${path.module}/dc1-server-consul.pem")
    join_environment   = "primary" # See environment_name above
    ui                 = true
  }

#  snapshot_agent = {
#    enabled      = true
#    interval     = "15m"
#    retention    = 10
#    s3_bucket_id = aws_s3_bucket.snapshots.id
#  }
}