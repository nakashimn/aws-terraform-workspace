################################################################################
# Settings
################################################################################
terraform {
  backend "s3" {
    bucket  = "nakashimn"
    region  = "ap-northeast-3"
    key     = "tfstate/develop.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region  = var.region
  profile = "terraform"
}

# AWSの情報
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
