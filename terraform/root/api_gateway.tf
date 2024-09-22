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
