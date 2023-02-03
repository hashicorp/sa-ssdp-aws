terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.50.0"
    }
    vault = {
      source = "hashicorp/vault"
      version = "3.12.0"
    }
  }
}


provider "aws" {
  # your AWS region
  region = var.region
}
