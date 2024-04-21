################################################################################
# Params
################################################################################
locals {
  name            = "openapi-sample"
  repository_name = "openapi_sample"
  version         = "develop"
}

################################################################################
# Repository
################################################################################
resource "aws_ecr_repository" "main" {
  name                 = local.repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

################################################################################
# Logger
################################################################################
resource "aws_cloudwatch_log_group" "main" {
  name              = local.name
  retention_in_days = 30
}

################################################################################
# Cluster
################################################################################
resource "aws_ecs_cluster" "main" {
  name = local.name
}

################################################################################
# LoadBalancer
################################################################################
resource "aws_lb" "main" {
  name               = "alb-openapi-sample"
  load_balancer_type = "network"
  internal           = true
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "main" {
  name        = "openapi-sample"
  target_type = "ip"
  vpc_id      = var.vpc_id
  port        = var.container_port
  protocol    = "TCP"
  health_check {
    port                = "traffic-port"
    protocol            = "TCP"
    interval            = 60
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "main" {
  depends_on = [
    aws_lb.main,
    aws_lb_target_group.main
  ]

  load_balancer_arn = aws_lb.main.arn
  port              = var.open_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

################################################################################
# ECS Service
################################################################################
resource "aws_ecs_service" "main" {
  depends_on = [
    aws_ecs_cluster.main,
    aws_ecs_task_definition.main,
    aws_lb_listener.main
  ]

  name            = local.name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.main.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = local.name
    container_port   = var.container_port
  }
}

resource "aws_ecs_task_definition" "main" {
  depends_on = [
    aws_ecr_repository.main,
    aws_cloudwatch_log_group.main
  ]

  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.ecs_task_execution_role.arn
  task_role_arn            = var.ecs_task_role.arn
  container_definitions = jsonencode(
    [
      {
        name      = local.name
        image     = "${aws_ecr_repository.main.repository_url}:${local.version}"
        cpu       = 512
        memory    = 1024
        essential = true
        environment = [
          { name = "PORT", value = tostring(var.container_port) }
        ]
        portMappings = [
          {
            containerPort = var.container_port
            hostPort      = var.container_port
          }
        ]
        logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-region        = var.region
            awslogs-stream-prefix = local.name
            awslogs-group         = aws_cloudwatch_log_group.main.name
          }
        }
      }
    ]
  )
}

################################################################################
# SecurityGroup
################################################################################
# SecurityGroup定義
resource "aws_security_group" "main" {
  name   = local.name
  vpc_id = var.vpc_id
}

# SecurityGroupRule(外部向けインバウンドルール)定義
resource "aws_security_group_rule" "ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  from_port         = var.container_port
  to_port           = var.container_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# SecurityGroupRule(アウトバウンドルール)定義
resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


################################################################################
# CodeBuild
################################################################################
resource "aws_codebuild_project" "main" {
  depends_on = [aws_codebuild_source_credential.main]

  name          = "codebuild-${local.name}"
  service_role  = var.codebuild_role.arn
  build_timeout = 60

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "BITBUCKET_AUTHORIZATION_TOKEN"
      value = aws_codebuild_source_credential.main.token
    }
  }

  source {
    buildspec = templatefile("${path.module}/buildspec/buildspec.yaml", {
      account_id      = var.account_id
      region          = var.region
      repository_name = local.repository_name
      repository_url  = aws_ecr_repository.main.repository_url
      version         = local.version
    })
    type                = "BITBUCKET"
    location            = "https://bitbucket.org/nakashimn/${local.repository_name}.git"
    git_clone_depth     = 1
    report_build_status = false
  }

  lifecycle {
    ignore_changes = [project_visibility]
  }

  source_version = "develop"

  artifacts {
    type = "NO_ARTIFACTS"
  }
}

resource "aws_codebuild_source_credential" "main" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "BITBUCKET"
  token       = var.bitbucket_access_token
}

resource "aws_codebuild_webhook" "main" {
  depends_on = [aws_codebuild_project.main]

  project_name = aws_codebuild_project.main.name
  build_type = "BUILD"
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
