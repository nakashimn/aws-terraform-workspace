output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "eventbridge_scheduler_role_arn" {
  value = aws_iam_role.eventbridge_scheduler_role.arn
}

output "s3_common_bucket" {
  value = aws_s3_bucket.terraform
}
