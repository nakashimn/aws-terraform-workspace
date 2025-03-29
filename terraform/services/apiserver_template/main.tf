################################################################################
# Settings
################################################################################
terraform {
  backend "s3" {}
}

provider "aws" {
  region                   = var.region
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform"
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

data "aws_route53_zone" "main" { name = var.endpoint_domain }
data "aws_s3_bucket" "documents" { bucket = "${local.service_group}-documents-${var.environment}" }
data "aws_ecr_repository" "codebuild_notification" { name = "codebuild-notification-webhook" }
data "aws_ecr_pull_through_cache_rule" "ecr_public" { ecr_repository_prefix = "ecr-public-${var.environment}" }
data "aws_ssm_parameter" "docker_username" { name = "/dockerhub/username" }
data "aws_ssm_parameter" "docker_password" { name = "/dockerhub/password" }
data "aws_ssm_parameter" "build_notification" { name = "/webhook/slack-codebuild" }

########################################################################################
# Modules
########################################################################################
# codebuild-notificationモジュール
module "codebuild_notification" {
  source = "../../modules/codebuild-notification-webhook-lambda"

  codebuild_notification_repo_url = data.aws_ecr_repository.codebuild_notification.repository_url
  codebuild_project_name          = aws_codebuild_project.main.name
  random_id_length                = 2
  webhook_url                     = data.aws_ssm_parameter.build_notification.value
}
