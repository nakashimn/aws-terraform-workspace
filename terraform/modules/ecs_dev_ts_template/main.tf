################################################################################
# Params
################################################################################
locals {
  name    = "ecs-dev-ts-template"
  version = "0.0.1"
}

################################################################################
# Repository
################################################################################
resource "aws_ecr_repository" "main" {
  name                 = "ecs_dev_ts_template"
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
# Scheduler
################################################################################
resource "aws_cloudwatch_event_rule" "main" {
  name                = local.name
  schedule_expression = "cron(0 15 * * ? *)" # UTC
}

resource "aws_cloudwatch_event_target" "main" {
  rule     = aws_cloudwatch_event_rule.main.name
  arn      = aws_ecs_cluster.main.arn
  role_arn = var.eventbridge_scheduler_role.arn
  ecs_target {
    task_definition_arn = aws_ecs_task_definition.main.arn
    task_count          = 1
    launch_type         = "FARGATE"
    network_configuration {
      assign_public_ip = false  # subnet.map_public_ip_on_launchに合わせる
      subnets          = var.subnet_ids
      security_groups  = [aws_security_group.main.id]
    }
  }
}

################################################################################
# Task
################################################################################
resource "aws_ecs_cluster" "main" {
  name = local.name
}

resource "aws_ecs_task_definition" "main" {
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
        name      = aws_ecr_repository.main.name
        image     = "${aws_ecr_repository.main.repository_url}:${local.version}"
        cpu       = 512
        memory    = 1024
        essential = true
        environment = [
          { name = "PORT", value = "3000" }
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

resource "aws_security_group" "main" {
  name   = "main"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
