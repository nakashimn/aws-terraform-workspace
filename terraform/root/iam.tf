################################################################################
# Policy
################################################################################
# APIGateway用Policy
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
