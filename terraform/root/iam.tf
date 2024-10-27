################################################################################
# Role
################################################################################
# APIGateway用ロール
resource "aws_iam_role" "api_gateway" {
  name = "${local.service_group}-APIGateway-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "apigateway.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  ]
}

################################################################################
# Policy
################################################################################
# APIGateway用ポリシー
data "aws_iam_policy_document" "api_gateway" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.main.id}/*"]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["0.0.0.0/0"]
    }
  }
}

# APIGatewayLogging用ポリシー
resource "aws_iam_role_policy" "api_gateway_log_policy" {
  name = "${local.service_group}-APIGatewayLogPolicy-${var.environment}"
  role = aws_iam_role.api_gateway.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "*"
        }
      ]
    }
  )
}
