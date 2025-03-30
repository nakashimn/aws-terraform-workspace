################################################################################
# CodePipeline
################################################################################
# CodePipelineの設定
resource "aws_codepipeline" "main" {
  name     = "${local.appname}-${var.environment}"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = [ "source_output" ]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.bitbucket.arn
        FullRepositoryId = local.repository_name
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = [ "source_output" ]
      output_artifacts = [ ]
      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }
}

################################################################################
# CodeConnection
################################################################################
# CodeConnection定義(bitbucket)
resource "aws_codestarconnections_connection" "bitbucket" {
  name     = "${substr("bldnotif-${var.service}", 0, 31-local.len_suffix)}-${var.environment}"
  provider = "BitBucket"
}

################################################################################
# CodeBuild
################################################################################
# CodeBuildプロジェクト
resource "aws_codebuild_project" "main" {
  name           = "${local.appname}-codebuild-${var.environment}"
  service_role   = aws_iam_role.codebuild.arn
  build_timeout  = 30

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/buildspec/buildspec.yaml", {
      account_id      = data.aws_caller_identity.current.id
      image_tag       = "latest"
      region          = var.region
      repository_url  = aws_ecr_repository.main.repository_url
    })
  }
  artifacts {
    type = "CODEPIPELINE"
  }

  lifecycle {
    ignore_changes = [ project_visibility ]
  }
}
