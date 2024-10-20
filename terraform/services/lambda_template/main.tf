################################################################################
# Settings
################################################################################
terraform {
  backend "s3" {
    bucket  = "nakashimn"
    region  = "ap-northeast-3"
    key     = "tfstate/lambda_template.tfstate"
    encrypt = true
  }
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
data "aws_ecr_repository" "codebuild_notification" { name = "codebuild-notification-webhook" }

########################################################################################
# Modules
########################################################################################
# codebuild-notificationモジュール
module "codebuild_notification" {
  source = "../../modules/codebuild-notification-webhook-lambda"

  codebuild_notification_repo_url = data.aws_ecr_repository.codebuild_notification.repository_url
  codebuild_project_name          = aws_codebuild_project.main.name
  region                          = var.region
  webhook_url                     = "https://hooks.slack.com/services/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"
}
