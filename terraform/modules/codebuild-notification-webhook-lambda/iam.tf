################################################################################
# Role
################################################################################
# Lambda用ロール
resource "aws_iam_role" "lambda" {
  name               = "LambdaRole-build-notification-${substr(var.codebuild_project_name, 0, 34)}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "lambda.amazonaws.com" }
  )
  managed_policy_arns = [
    aws_iam_policy.lambda.arn
  ]
}

# EventBridge用ロール
resource "aws_iam_role" "eventbridge_scheduler" {
  name = "EventbridgeRole-build-notification-${substr(var.codebuild_project_name, 0, 28)}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "events.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
  ]
}

################################################################################
# Policy
################################################################################
# Lambda用ポリシー
resource "aws_iam_policy" "lambda" {
  name = "LambdaPolicy-build-notification-${substr(var.codebuild_project_name, 0, 32)}"
  policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Effect" = "Allow",
          "Action" = [
            "ecr:*",
            "logs:*",
            "s3:*"
          ],
          "Resource" : "*"
        },
      ]
    }
  )
}
