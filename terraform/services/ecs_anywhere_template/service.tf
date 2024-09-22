################################################################################
# Cluster
################################################################################
resource "aws_ecs_cluster" "main" {
  name = local.name
}

################################################################################
# ECS Service
################################################################################
resource "aws_ecs_service" "ecs_anywhere_service" {
  name            = "${local.service_group}-${local.name}-ecs-anywhere-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ecs_anywhere_task.arn
  desired_count   = 1
  launch_type     = "EXTERNAL"
}

resource "aws_ecs_task_definition" "ecs_anywhere_task" {
  family                   = "${local.service_group}-${local.name}-ecs-anywhere-task-${var.environment}"
  network_mode             = "bridge"
  requires_compatibilities = ["EXTERNAL"]

  container_definitions = jsonencode([{
    name      = "nginx"
    image     = "nginx:latest"
    cpu       = 512
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}
