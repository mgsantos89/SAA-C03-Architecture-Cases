terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

#backend "s3" {
#  bucket = "<BUCKET>"
#  key    = "<PATH>/terraform.tfstate" 
#  region = "<BUCKET-REGION>"
#}

}

provider "aws" {
  region = "us-east-1"
}