################################################################################
# Lambda                                                                       #
################################################################################
# lambda関数定義
resource "aws_lambda_function" "codebuild_notification" {
  function_name = "notification-${var.codebuild_project_name}"
  package_type  = "Image"
  image_uri     = "${var.codebuild_notification_repo_url}:latest"
  role          = aws_iam_role.lambda.arn
  publish       = true

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      WEBHOOK_URL         = var.webhook_url
      IN_PROGRESS_MESSAGE = var.in_progress_message
      SUCCEEDED_MESSAGE   = var.succeeded_message
      FAILED_MESSAGE      = var.failed_message
    }
  }
}

# lambda実行パーミッション定義
resource "aws_lambda_permission" "codebuild_notification" {
  statement_id  = "AllowExecutionFromEventBridge-${var.codebuild_project_name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.codebuild_notification.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.codebuild_notification.arn
}
