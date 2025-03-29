################################################################################
# AutoScaling
################################################################################
# AutoScaling定義
resource "aws_appautoscaling_target" "main" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  role_arn           = aws_iam_role.autoscaling.arn

  min_capacity       = var.autoscaling_config.min_capacity
  max_capacity       = var.autoscaling_config.max_capacity

  lifecycle {
    ignore_changes = [ role_arn ]
  }
}

# AutoScalingPolicy(ScaleOut)定義
resource "aws_appautoscaling_policy" "scale_out" {
  name               = "${local.service_group}-${local.name}-scaleout-${var.environment}"
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

# AutoScalingPolicy(ScaleIn)定義
resource "aws_appautoscaling_policy" "scale_in" {
  name               = "${local.service_group}-${local.name}-scalein-${var.environment}"
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

# AutoScalingAlarm(ScaleOut)定義
resource "aws_cloudwatch_metric_alarm" "alarm_cpu_high" {
  alarm_name    = "${local.service_group}-${local.name}-cpuhigh-${var.environment}"
  alarm_actions = [ aws_appautoscaling_policy.scale_out.arn ]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"
  threshold           = "50"
  period              = "60"
  evaluation_periods  = "1"

  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}

# AutoScalingAlarm(ScaleIn)定義
resource "aws_cloudwatch_metric_alarm" "alarm_cpu_high" {
  alarm_name    = "${local.service_group}-${local.name}-cpulow-${var.environment}"
  alarm_actions = [ aws_appautoscaling_policy.scale_in.arn ]

  comparison_operator = "LessThanOrEqualToThreshold"
  statistic           = "Average"
  threshold           = "10"
  period              = "60"
  evaluation_periods  = "10"

  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}
