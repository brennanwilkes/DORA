resource "aws_s3_bucket" "terraform_backend_bucket" {
      bucket = "terraform-state-boo6tzycmonxynn0k0ubavdhpd4s3ctpp2hzahewr6gy8"
}

terraform {
  required_providers {
    aws =  {
    source = "hashicorp/aws"
    version = ">= 2.7.0"
    }
  }
}

provider "aws" {
    region = "us-west-2"
}

