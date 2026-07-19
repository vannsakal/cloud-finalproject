terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {

    bucket = "terraform-statefile-dingdong-bucket"
    key = "project/terraform.tfstate"
    region = "ap-southeast-1"
    encrypt = true
    use_use_lockfile = true    
  }
}

provider "aws" {
    region = "${var.aws_region}"
    default_tags {
      tags = {

        Environment = "${var.environment}"
        CreatedBy = "terraform"

      }
    }
}

