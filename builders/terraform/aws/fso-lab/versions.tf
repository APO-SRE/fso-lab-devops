# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.2.6"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.25"
    }

    kubernetes = {
      version = "~> 2.12"
    }

    null = {
      source = "hashicorp/null"
      version = ">= 3.1"
    }

    random = {
      source = "hashicorp/random"
      version = ">= 3.3"
    }
  }
}
