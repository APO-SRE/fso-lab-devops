# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.2.3"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.20"
    }

    kubernetes = {
      version = "~> 2.11"
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
