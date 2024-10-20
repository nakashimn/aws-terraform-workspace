########################################################################################
# EventBridge
########################################################################################
# EventBridgeルール定義
resource "aws_cloudwatch_event_rule" "codebuild_notification" {
  name        = "codebuild-notification-${substr(var.codebuild_project_name, 0 , 41)}"
  event_pattern = jsonencode(
    {
      "source": ["aws.codebuild"],
      "detail-type": ["CodeBuild Build State Change"],
      "detail": {
        "project-name": [var.codebuild_project_name],
        "build-status": [
          "IN_PROGRESS",
          "SUCCEEDED",
          "FAILED"
        ]
      }
    }
  )
}

# EventBridgeのターゲット定義
resource "aws_cloudwatch_event_target" "codebuild_notification" {
  rule      = aws_cloudwatch_event_rule.codebuild_notification.name
  target_id = "lambda"
  arn       = aws_lambda_function.codebuild_notification.arn

  depends_on = [ aws_lambda_function.codebuild_notification ]
}
