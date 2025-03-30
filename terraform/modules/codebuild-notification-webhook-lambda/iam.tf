################################################################################
# Role
################################################################################
# Lambda用ロール
resource "aws_iam_role" "lambda" {
  name               = substr("Lambda-build-notification${random_id.main.b64_url}-${var.codebuild_project_name}", 0, 64)
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "lambda.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
}

# EventBridge用ロール
resource "aws_iam_role" "eventbridge_scheduler" {
  name = substr("Eventbridge-bn-${var.codebuild_project_name}", 0, 64)
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "events.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
  ]
}
