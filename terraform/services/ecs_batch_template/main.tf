################################################################################
# Settings
################################################################################
terraform {
  backend "s3" {}
}

provider "aws" {
  region  = var.region
  profile = "terraform"
}

provider "aws" {
  alias   = "as_global"
  region  = "us-east-1"
  profile = "terraform"
}


################################################################################
# DataSources
################################################################################
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_vpc" "root" {
  filter {
    name   = "tag:Name"
    values = ["${local.service_group}-vpc-${var.environment}"]
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

data "aws_s3_bucket" "documents" { bucket = "${local.service_group}-documents-${var.environment}" }
data "aws_ssm_parameter" "main" { name = "/bitbucket-access-token/ecs_dev_py_template" }
data "aws_ssm_parameter" "build_notification" { name = "/webhook/slack-codebuild" }
