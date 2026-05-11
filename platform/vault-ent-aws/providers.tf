# Copyright IBM Corp. 2022, 2026

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.50.0"
    }
  }
}

provider "aws" {
  # your AWS region
  region = var.region
}
