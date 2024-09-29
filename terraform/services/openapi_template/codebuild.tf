################################################################################
# CodeBuild
################################################################################
# Codebuildプロジェクト定義
resource "aws_codebuild_project" "main" {
  name           = "${local.service_group}-${local.name}-codebuild-${var.environment}"
  service_role   = aws_iam_role.codebuild.arn
  source_version = "develop"
  build_timeout  = 60

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "BITBUCKET_OAUTH_TOKEN"
      value = aws_codebuild_source_credential.main.token
    }
  }

  source {
    buildspec = templatefile("${path.module}/buildspec/${var.environment}.yaml", {
      account_id      = data.aws_caller_identity.current.id
      cluster_name    = aws_ecs_cluster.main.name
      ecs_service     = aws_ecs_service.main.name
      image_tag       = var.environment == "pro" ? var.app_version : var.build_branch
      region          = var.region
      repository_url  = aws_ecr_repository.main.repository_url
    })
    type                = "BITBUCKET"
    location            = local.bitbucket_repository_url
    git_clone_depth     = 1
    report_build_status = false
  }

  lifecycle {
    ignore_changes = [project_visibility]
  }

  artifacts {
    type                = "S3"
    location            = data.aws_s3_bucket.documents.bucket
    encryption_disabled = true
  }
}

# Bitbucketのアクセス認証定義
resource "aws_codebuild_source_credential" "main" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "BITBUCKET"
  token       = var.bitbucket_access_token
}

# CodebuildWebhook定義
resource "aws_codebuild_webhook" "main" {
  project_name = aws_codebuild_project.main.name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }
    filter {
      type    = "HEAD_REF"
      pattern = "develop"
    }
  }
}
