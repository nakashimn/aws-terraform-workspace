################################################################################
# CodeBuild
################################################################################
# CodeBuildプロジェクト
resource "aws_codebuild_project" "main" {
  name           = var.repository_name
  service_role   = aws_iam_role.codebuild.arn
  source_version = "main"
  build_timeout  = 60

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "GITHUB_OAUTH_TOKEN"
      value = aws_codebuild_source_credential.main.token
    }
  }

  source {
    buildspec = templatefile("${path.module}/buildspec/buildspec.yaml", {
      account_id      = data.aws_caller_identity.current.id
      image_tag       = var.image_tag
      region          = var.region
      repository_url  = aws_ecr_repository.main.repository_url
    })
    type                = "GITHUB"
    location            = "https://github.com/nakashimn/codebuild-notification-webhook.git"
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

# リポジトリのクレデンシャル情報
resource "aws_codebuild_source_credential" "main" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_access_token
}

# CodeBuildのWebhookトリガー定義
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
      pattern = "main"
    }
  }
}

# CodeBuild実行
resource "null_resource" "start_codebuild" {
  provisioner "local-exec" {
    command = "aws codebuild start-build --project-name ${aws_codebuild_project.main.name} --region ${var.region}"
  }

  # CodeBuildプロジェクト作成後に実行するよう依存関係を設定
  depends_on = [aws_codebuild_project.main]
}
