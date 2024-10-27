################################################################################
# APIGateway
################################################################################
# APIGateway定義
resource "aws_api_gateway_rest_api" "main" {
  name = "${local.service_group}-api-gateway-${var.environment}"
}

# APIGatewayとアクセス制御用Policyの紐づけ
resource "aws_api_gateway_rest_api_policy" "internal" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  policy      = data.aws_iam_policy_document.api_gateway.json
}

# APIGateway用カスタムドメイン定義
resource "aws_api_gateway_domain_name" "main" {
  domain_name              = aws_route53_zone.main.name
  regional_certificate_arn = aws_acm_certificate_validation.main.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Logging用Role紐づけ
resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway.arn
}
