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
    aws_iam_policy.lambda.arn
  ]
}

# EventBridge用ロール
resource "aws_iam_role" "eventbridge_scheduler" {
  name = substr("Eventbridge-build-notification${random_id.main.b64_url}-${var.codebuild_project_name}", 0, 64)
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
  name = substr("Lambda-build-notification-${random_id.main.b64_url}-${var.codebuild_project_name}", 0, 64)
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
