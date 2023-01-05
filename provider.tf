terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>4.48.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }
}

provider "aws" {
  # Configuration options
    region = "us-east-1"
    shared_credentials_files = [/home/tagoro/.aws/credentials]
}