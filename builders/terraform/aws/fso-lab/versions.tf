# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.1.8"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.10"
    }

    kubernetes = {
      version = "~> 2.10"
    }

    null = {
      source = "hashicorp/null"
      version = ">= 3.1"
    }

    random = {
      source = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
