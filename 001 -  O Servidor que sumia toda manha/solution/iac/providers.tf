terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.72.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.4.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.9.1"
    }
  }

#backend "s3" {
#  bucket = "<BUCKET>"
#  key    = "<PATH>/terraform.tfstate" 
#  region = "<BUCKET-REGION>"
#}

}

provider "aws" {
  region = var.region
}