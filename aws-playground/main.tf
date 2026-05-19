terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "temp_bucket" {
  bucket_prefix = "brtk__spacelift-playground__"
  bucket = "spacelift-managed-alert"
  tags = {
    "ManagedBy" = "Spacelift"
  }
}