resource "local_sensitive_file" "generate_tfvars" {
  content = templatefile("${path.module}/templates/generate-tfvars.tpl", {
    region                   = var.region
    instance_subnets         = jsonencode(module.vpc_platform_services.private_subnets.*)
    vpc_platform_services_id = module.vpc_platform_services.vpc_id
    vpc_cidr_blocks          = jsonencode([module.vpc_platform_services.vpc_cidr_block, module.vpc_app_microservices.vpc_cidr_block, module.vpc_payments.vpc_cidr_block])
    })
  filename          = "../inputs/terraform.tfvars-platform"
}
