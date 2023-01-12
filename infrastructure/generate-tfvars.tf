# REQUIRED SECRETS

# | `consul_cluster_version` | String | SemVer string for each cluster deployment. Used for autopilot upgrade migrations, must be incremented to roll out new nodes. |
# | `tag_owner` | String | Denotes the user/entity responsible for maintaining this cluster. |
# | `instance_subnets` | List(String) | List of AWS subnet IDs for instances to be launched within. Generally private (NAT) subnets. |
# | `vpc_id` | String | AWS VPC to create resources within. |
# | `ami_id` | String | AMI to launch instances using. |
# | `key_name` | String | Key pair name (in AWS) to attach to launched instances. |
# | `consul_secrets` | [Object](#secrets-management) | Object containg AWS Secrets Manager and AWS KMS references for token and key retrieval. |
# | `environment_name` | String | Unique environment name for each cluster. Used for auto-join and to prevent resource name collisions. |
# | `consul_agent`


resource "local_sensitive_file" "generate_tfvars" {
  content = templatefile("${path.module}/templates/generate-tfvars.tpl", {
    consul_cluster_version   = ""
    tag_owner                = ""
    instance_subnets         = jsonencode(module.vpc_platform_services.public_subnets.*)
    vpc_platform_services_id = module.vpc_platform_services.vpc_id
    ami_id                   = data.aws_ami.ubuntu.id
    key_name                 = module.key_pair.key_pair_key_name
    consul_secrets           = ""
    environment_name         = ""
    consul_agent             = ""
    })
  filename          = "../inputs/terraform.tfvars-platform"
}

# vpc_id
# eks_cluster_name
# vpc_subnets
# 