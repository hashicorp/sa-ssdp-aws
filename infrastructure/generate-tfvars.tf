resource "local_sensitive_file" "generate_tfvars" {
  content = templatefile("${path.module}/templates/generate-tfvars.tpl", {
    region                   = var.region
    instance_subnets         = jsonencode(module.vpc_platform_services.public_subnets.*)
    vpc_platform_services_id = module.vpc_platform_services.vpc_id
    key_name                 = module.key_pair.key_pair_key_name
    })
  filename          = "../inputs/terraform.tfvars-platform"
}
