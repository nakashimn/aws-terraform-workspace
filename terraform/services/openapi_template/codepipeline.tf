################################################################################
# CodePipeline
################################################################################
# CodePipelineの設定
resource "aws_codepipeline" "main" {
  name     = "${local.service_group}-${local.name}-codepipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

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
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.gitlab.arn
        FullRepositoryId = local.gitlab_repository_name
        BranchName       = var.build_branch
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
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "CodeDeploy"
      input_artifacts  = ["build_output"]
      version          = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.main.name
        DeploymentGroupName = aws_codedeploy_deployment_group.main.deployment_group_name
      }
    }
  }
}

################################################################################
# CodeConnection
################################################################################
# CodeConnection定義(bitbucket)
resource "aws_codestarconnections_connection" "bitbucket" {
  name          = "connect-bitbucket-${var.environment}"
  provider_type = "Bitbucket"
}

# CodeConnection定義
resource "aws_codestarconnections_connection" "gitlab" {
  name          = "connect-gitlab-${var.environment}"
  provider_type = "GitLab"
}

################################################################################
# CodeBuild
################################################################################
# Codebuildプロジェクト定義
resource "aws_codebuild_project" "main" {
  name           = "${local.service_group}-${local.name}-codebuild-${var.environment}"
  service_role   = aws_iam_role.codebuild.arn
  build_timeout  = 30

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "BITBUCKET_OAUTH_TOKEN"
      value = data.aws_ssm_parameter.main.value
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/buildspec/${var.environment}.yaml", {
      account_id       = data.aws_caller_identity.current.id
      bucket_name      = data.aws_s3_bucket.documents.bucket
      cluster_name     = aws_ecs_cluster.main.name
      container_name   = aws_ecr_repository.main.name
      container_port   = var.container_port
      docker_username  = data.aws_ssm_parameter.docker_username.value
      docker_password  = data.aws_ssm_parameter.docker_password.value
      ecs_service      = aws_ecs_service.main.name
      image_tag        = var.environment == "pro" ? var.app_version : var.build_branch
      region           = var.region
      repository_url   = aws_ecr_repository.main.repository_url
      task_family_name = aws_ecs_task_definition.main.family
    })
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  lifecycle {
    ignore_changes = [project_visibility]
  }
}

################################################################################
# CodeDeploy
################################################################################
# CodeDeploy定義
resource "aws_codedeploy_app" "main" {
  name             = "${local.service_group}-${local.name}-codedeploy-${var.environment}"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "main" {
  app_name               = aws_codedeploy_app.main.name
  deployment_group_name  = aws_codedeploy_app.main.name
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.main.name
  }

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"  # タイムアウト時にデプロイを続行
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1440 # 1day
    }
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.main[0].name
      }
      target_group {
        name = aws_lb_target_group.main[1].name
      }
      prod_traffic_route {
        listener_arns = [aws_lb_listener.main.arn]
      }
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
