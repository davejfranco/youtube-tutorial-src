provider "aws" {
  region                      = "eu-west-1"
  access_key                  = "fake"
  secret_key                  = "fake"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_force_path_style         = true

  endpoints {
    ec2             = "http://localhost:4566"
    route53         = "http://localhost:4566"
    route53resolver = "http://localhost:4566"
    s3              = "http://localhost:4566"
    s3control       = "http://localhost:4566"
    iam             = "http://localhost:4566"
  }

  default_tags {
    tags = {
      Environment = "Local"
      Service     = "LocalStack"
    }
  }
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt or via a backend.hcl file. See
  # https://www.terraform.io/docs/backends/config.html#partial-configuration
  #  backend "s3" {}

  # Only allow this Terraform version. Note that if you upgrade to a newer version, Terraform won't allow you to use an
  # older version, so when you upgrade, you should upgrade everyone on your team and your CI servers all at once.
  required_version = "~> 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.60.0, <= 4.22.0"
    }
  }
}