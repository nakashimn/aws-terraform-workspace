################################################################################
# Params
################################################################################
locals {
  name            = "openapi-sample"
  repository_name = "openapi_sample"
  version         = "develop"
}

################################################################################
#
################################################################################
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_vpc" "root" {
  filter {
    name = "tag:name"
    values = ["terraform"]
  }
}
data "aws_subnets" "public" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.root.id]
  }
  filter {
    name = "map-public-ip-on-launch"
    values = [true]
  }
}

data "aws_subnet" "public" {
    for_each = toset(data.aws_subnets.public.ids)

    vpc_id  = data.aws_vpc.root.id
    id      = each.value
}

data "aws_iam_role" "ecs_task_execution" { name = "ECSTaskExecutionRole" }
data "aws_iam_role" "ecs_task" { name = "ECSTaskRole" }
data "aws_iam_role" "codebuild" { name = "CodeBuildRole" }

data "aws_api_gateway_rest_api" "main" { name = "aws-api-gateway-terraform" }
data "aws_api_gateway_resource" "main" {
  rest_api_id = data.aws_api_gateway_rest_api.main.id
  path = "/"
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
  subnets            = data.aws_subnets.public.ids
}

resource "aws_lb_target_group" "main" {
  name        = "openapi-sample"
  target_type = "ip"
  vpc_id      = data.aws_vpc.root.id
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
  name            = local.name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = data.aws_subnets.public.ids
    security_groups  = [aws_security_group.main.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = aws_ecr_repository.main.name
    container_port   = var.container_port
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn            = data.aws_iam_role.ecs_task.arn
  container_definitions = jsonencode(
    [
      {
        name      = aws_ecr_repository.main.name
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
  vpc_id = data.aws_vpc.root.id
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
  name          = "codebuild-${local.name}"
  service_role  = data.aws_iam_role.codebuild.arn
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
      account_id      = data.aws_caller_identity.current.id
      region          = var.region
      repository_name = aws_ecr_repository.main.name
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


################################################################################
# APIGateway
################################################################################
# APIGatewayとNLBのDNSの紐づけ
resource "aws_api_gateway_integration" "openapi_sample" {
  count                   = length(aws_api_gateway_method.main)
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.main.id
  http_method             = aws_api_gateway_method.main[count.index].http_method
  integration_http_method = aws_api_gateway_method.main[count.index].http_method
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.dns_name}/{proxy}"
  cache_key_parameters    = ["method.request.path.proxy"]
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy" # Proxy統合有効化
  }

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.openapi_sample.id
}

# APIGatewayとVPCLinkの紐づけ
resource "aws_api_gateway_vpc_link" "openapi_sample" {
  name        = "api-gateway-vpc-link-openapi-sample"
  target_arns = [module.openapi_sample.aws_lb.arn]
}
