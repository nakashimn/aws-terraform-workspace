################################################################################
# Lambda                                                                       #
################################################################################
# lambda関数定義
resource "aws_lambda_function" "codebuild_notification" {
  function_name = "codebuild-notification-${var.environment}"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.main.repository_url}:${var.build_branch}"
  role          = aws_iam_role.lambda.arn
  publish       = true

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      WEBHOOK_URL         = ""
      IN_PROGRESS_MESSAGE = "ビルドを開始しました。"
      SUCCEEDED_MESSAGE   = "ビルドが成功しました！"
      FAILED_MESSAGE      = "ビルドが失敗しました..."
    }
  }

  lifecycle {
    ignore_changes = [
      last_modified
    ]
  }
}

# lambda実行パーミッション定義
resource "aws_lambda_permission" "codebuild_notification" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.codebuild_notification.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.codebuild_notification.arn
}
