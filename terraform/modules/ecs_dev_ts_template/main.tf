locals {
  name    = "ecs_dev_ts_template"
  version = "0.0.1"
}

################################################################################
# Repository
################################################################################
resource "aws_ecr_repository" "ecs_dev_ts_template" {
  name                 = local.name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

################################################################################
# Logger
################################################################################
resource "aws_cloudwatch_log_group" "ecs_dev_ts_template" {
  name              = local.name
  retention_in_days = 30
}

################################################################################
# Scheduler
################################################################################
resource "aws_cloudwatch_event_rule" "ecs_dev_ts_template" {
  name                = local.name
  schedule_expression = "cron(0 15 * * ? *)" # UTC
}

resource "aws_cloudwatch_event_target" "ecs_dev_ts_template" {
  rule     = aws_cloudwatch_event_rule.ecs_dev_ts_template.name
  arn      = aws_ecs_cluster.ecs_dev_ts_template.arn
  role_arn = var.resources.eventbridge_scheduler_role_arn
  ecs_target {
    task_definition_arn = aws_ecs_task_definition.ecs_dev_ts_template.arn
    network_configuration {
      assign_public_ip = false
      subnets          = var.config.subnet_ids
      security_groups  = var.config.security_group_ids
    }
  }
}

################################################################################
# Task
################################################################################
resource "aws_ecs_cluster" "ecs_dev_ts_template" {
  name = local.name
}

resource "aws_ecs_task_definition" "ecs_dev_ts_template" {
  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.resources.ecs_task_execution_role_arn
  task_role_arn            = var.resources.ecs_task_role_arn
  container_definitions = jsonencode(
    [
      {
        name      = local.name
        image     = "${aws_ecr_repository.ecs_dev_ts_template.repository_url}:${local.version}"
        cpu       = 512
        memory    = 1024
        essential = true
        environment = [
          { name = "PORT", value = "3000" }
        ]
        logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-region        = var.config.region
            awslogs-stream-prefix = local.name
            awslogs-group         = aws_cloudwatch_log_group.ecs_dev_ts_template.name
          }
        }
      }
    ]
  )
}
