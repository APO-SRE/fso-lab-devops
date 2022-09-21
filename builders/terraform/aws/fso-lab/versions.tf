# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.31"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.13"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.6"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.1"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.4"
    }
  }
}
