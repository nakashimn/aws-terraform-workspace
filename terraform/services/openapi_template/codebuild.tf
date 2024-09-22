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
    buildspec = templatefile("${path.module}/buildspec/buildspec.yaml", {
      account_id      = data.aws_caller_identity.current.id
      region          = var.region
      repository_name = aws_ecr_repository.main.name
      repository_url  = aws_ecr_repository.main.repository_url
      version         = local.version
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
    type = "NO_ARTIFACTS"
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
