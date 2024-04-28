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
  role_arn = aws_iam_role.eventbridge_scheduler.arn
  ecs_target {
    task_definition_arn = aws_ecs_task_definition.main.arn
    task_count          = 1
    launch_type         = "FARGATE"
    network_configuration {
      assign_public_ip = true # subnet.map_public_ip_on_launchに合わせる
      subnets          = data.aws_subnets.public.ids
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
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
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
