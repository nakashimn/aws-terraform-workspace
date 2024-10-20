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
  region                   = var.region
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform"
}

provider "aws" {
  alias                    = "as_global"
  region                   = "us-east-1"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform"
}

# AWSの情報
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

########################################################################################
# Modules
########################################################################################
# codebuild-notificationリポジトリ
module "codebuild-notirifation-webhook" {
  source = "../modules/codebuild-notification-webhook-repo"

  image_tag       = "latest"
  region          = var.region
  repository_name = "codebuild-notification-webhook"
}
