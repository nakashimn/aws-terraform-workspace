################################################################################
# AutoScaling
################################################################################
# AutoScaling定義
resource "aws_appautoscaling_target" "main" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  role_arn           = data.aws_iam_role.autoscaling.arn

  min_capacity       = 1
  max_capacity       = 2
}

# AutoScalingPolicy(ScaleOut)定義
resource "aws_appautoscaling_policy" "scale_out" {
  name               = "autoscaling-scale-out-${local.name}"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

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
  name               = "autoscaling-scale-in-${local.name}"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }
}

# AutoScalingAlarm(ScaleOut)定義
resource "aws_cloudwatch_metric_alarm" "alarm_cpu_high" {
  alarm_name          = "alarm_cpu_utilization_high_${terraform.workspace}"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "75"

  period              = "60"
  evaluation_periods  = "1"
  statistic           = "Average"

  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_out.arn]
}

# AutoScalingAlarm(ScaleIn)定義
resource "aws_cloudwatch_metric_alarm" "alarm_cpu_low" {
  alarm_name          = "alarm_cpu_utilization_low_${terraform.workspace}"

  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = "10"

  period              = "60"
  evaluation_periods  = "1"
  statistic           = "Average"

  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_in.arn]
}
