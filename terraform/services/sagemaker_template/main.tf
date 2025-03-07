################################################################################
# Settings
################################################################################
terraform {
  backend "s3" {
    bucket  = "nakashimn-tfstate"
    region  = "ap-northeast-1"
    key     = "tfstate/sagemaker_template.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region  = var.region
  profile = "terraform"
}

################################################################################
# DataSources
################################################################################
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_vpc" "root" {
  filter {
    name   = "tag:name"
    values = ["terraform"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.root.id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = [true]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.root.id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = [false]
  }
}
