################################################################################
# Cluster
################################################################################
# クラスター定義
resource "aws_ecs_cluster" "main" {
  name = "${local.service_group}-${local.name}-${var.environment}"
}

################################################################################
# ECS Service
################################################################################
# サービス定義
resource "aws_ecs_service" "main" {
  name = "${local.service_group}-${local.name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [aws_security_group.main.id]
    assign_public_ip = false
  }
  deployment_controller {
    type = var.environment == "dev" ? "ECS" : "CODE_DEPLOY"
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.main[0].arn
    container_name   = aws_ecr_repository.main.name
    container_port   = var.container_port
  }

  dynamic "load_balancer" {
    for_each = ((var.environment == "dev") && (var.resource_toggles.enable_debug_nlb)) ? [true] : []
    content {
      target_group_arn = aws_lb_target_group.debug[0].arn
      container_name   = aws_ecr_repository.main.name
      container_port   = var.container_port
    }
  }

  # TaskDefinition変更時もCodePipelineからのサービス更新を正とする
  lifecycle {
    ignore_changes = [ task_definition, load_balancer ]
  }
}

# ECSタスク定義
resource "aws_ecs_task_definition" "main" {
  family                   = "${local.service_group}-${local.name}-${var.environment}"
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
        cpu       = 256
        memory    = 512
        essential = true
        environment = [
          { name = "PORT", value = tostring(var.container_port) },
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
            awslogs-stream-prefix = "${local.service_group}-${local.name}-${var.environment}"
            awslogs-group         = aws_cloudwatch_log_group.main.name
          }
        }
      }
    ]
  )
}
