################################################################################
# Role
################################################################################
# Codebuild用タスクロール
resource "aws_iam_role" "codebuild" {
  name = "${local.service_group}-${local.name}-CodeBuildRole-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "codebuild.amazonaws.com" }
  )
  managed_policy_arns = [
    aws_iam_policy.codebuild_role.arn
  ]
}

# Lambda用ロール
resource "aws_iam_role" "lambda" {
  name               = "${local.service_group}-${local.name}-LambdaRole-${var.environment}"
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
  name = "${local.service_group}-${local.name}-EventbridgeSchedulerRole-${var.environment}"
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
# CodeBuild用ポリシー
resource "aws_iam_policy" "codebuild_role" {
  name = "${local.service_group}-${local.name}-CodebuildRole-${local.name}"
  policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Effect" = "Allow",
          "Action" = [
            "ecr:*",
            "lambda:*",
            "logs:*",
            "s3:*"
          ],
          "Resource" : "*"
        },
      ]
    }
  )
}

# Lambda用ポリシー
resource "aws_iam_policy" "lambda" {
  name = "${local.service_group}-${local.name}-Lambda-${local.name}"
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
