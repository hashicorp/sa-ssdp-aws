resource "aws_s3_bucket" "vault_license_bucket" {
  bucket_prefix = "${var.resource_name_prefix}-vault-license"
  force_destroy = true
  tags = var.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vault_bucket_encryption" {
  bucket = aws_s3_bucket.vault_license_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "vault_license_bucket_versioning" {
  bucket = aws_s3_bucket.vault_license_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "vault_license_bucket_acl" {
  bucket = aws_s3_bucket.vault_license_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "vault_license_bucket" {
  bucket = aws_s3_bucket.vault_license_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_object" "vault_license" {
  bucket = aws_s3_bucket.vault_license_bucket.id
  key    = var.vault_license_name
  source = var.vault_license_filepath

  tags = var.common_tags
}
