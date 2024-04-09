locals {
  name    = "openapi_sample"
  version = "0.0.2"
}

################################################################################
# Repository
################################################################################
resource "aws_ecr_repository" "openapi_sample" {
  name                 = local.name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

################################################################################
# Logger
################################################################################
resource "aws_cloudwatch_log_group" "openapi_sample" {
  name              = local.name
  retention_in_days = 30
}

################################################################################
# Cluster
################################################################################
resource "aws_ecs_cluster" "openapi_sample" {
  name = local.name
}

################################################################################
# LoadBalancer
################################################################################
resource "aws_lb" "oepnapi_sample" {
  name               = "alb-openapi-sample"
  load_balancer_type = "application"
  internal           = false
  idle_timeout       = 60
  subnets            = var.config.subnet_ids
  security_groups    = var.config.security_group_ids
}

resource "aws_lb_target_group" "openapi_sample" {
  name        = "openapi-sample"
  target_type = "ip"
  vpc_id      = var.config.vpc_id
  port        = 3000
  protocol    = "HTTP"
}

resource "aws_lb_listener" "openapi_sample" {
  load_balancer_arn = aws_lb.oepnapi_sample.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.openapi_sample.arn
  }
}

################################################################################
# ECS Service
################################################################################
resource "aws_ecs_service" "openapi_sample" {
  depends_on = [aws_lb_listener.openapi_sample]

  name            = local.name
  cluster         = aws_ecs_cluster.openapi_sample.id
  task_definition = aws_ecs_task_definition.openapi_sample.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.config.subnet_ids
    security_groups  = var.config.security_group_ids
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.openapi_sample.arn
    container_name   = local.name
    container_port   = 3000
  }
}

resource "aws_ecs_task_definition" "openapi_sample" {
  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.resources.ecs_task_execution_role_arn
  task_role_arn            = var.resources.ecs_task_role_arn
  container_definitions = jsonencode(
    [
      {
        name      = local.name
        image     = "${aws_ecr_repository.openapi_sample.repository_url}:${local.version}"
        cpu       = 256
        memory    = 512
        essential = true
        environment = [
          { name = "PORT", value = "3000" }
        ]
        portMappings = [
          {
            containerPort = 3000
            hostPort      = 3000
          }
        ]
        logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-region        = var.config.region
            awslogs-stream-prefix = local.name
            awslogs-group         = aws_cloudwatch_log_group.openapi_sample.name
          }
        }
      }
    ]
  )
}
