resource "aws_secretsmanager_secret" "consul_secrets" {
  name = "example"
}

resource "aws_kms_key" "consul_key" {
  description             = "KMS key - Consul"
  deletion_window_in_days = 10
}

