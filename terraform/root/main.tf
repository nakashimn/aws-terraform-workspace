################################################################################
# Settings
################################################################################
terraform {
  required_version = "~>1.8.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.51.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region                   = var.region
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform"

  default_tags {
    tags = {
      Country     = var.country
      Environment = var.environment
      Service     = var.service
    }
  }
}

provider "aws" {
  alias                    = "as_global"
  region                   = "us-east-1"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform"

  default_tags {
    tags = {
      Country     = var.country
      Environment = var.environment
      Service     = var.service
    }
  }
}

# AWSの情報
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_availability_zones" "as_global" {
  provider = aws.as_global
}

########################################################################################
# Modules
########################################################################################
# codebuild-notificationリポジトリ
module "codebuild_notification" {
  source = "../modules/codebuild-notification-webhook-repo"

  image_tag       = "latest"
  profile         = var.profile
  region          = var.region
  repository_name = "codebuild-notification-webhook"
}
