################################################################################
# APIGateway
################################################################################
# APIGateway定義
resource "aws_api_gateway_rest_api" "main" {
  name = "aws-api-gateway-terraform"
}

# APIGatewayとアクセス制御用Policyの紐づけ
resource "aws_api_gateway_rest_api_policy" "internal" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  policy      = data.aws_iam_policy_document.api_gateway.json
}

# APIGatewayデプロイ定義
resource "aws_api_gateway_deployment" "main" {

  rest_api_id = aws_api_gateway_rest_api.main.id
  triggers = {
    redeployment = sha1(
      jsonencode(
        []
      )
    )
  }
}

# APIデプロイ先Stage定義
resource "aws_api_gateway_stage" "main" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.main.id
  stage_name    = "develop"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format          = replace(file("${path.module}/assets/logformat/api_gateway.json"), "\n", "")
  }
}

# Logging用Role紐づけ
resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway.arn
}

# APIGateway用Logger定義
resource "aws_cloudwatch_log_group" "api_gateway" {
  name = "/api-gateway/"
}

# APIGateway用カスタムドメイン定義
resource "aws_api_gateway_domain_name" "main" {
  domain_name              = aws_route53_zone.main.name
  regional_certificate_arn = aws_acm_certificate_validation.main.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# APIGatewayとカスタムドメインの紐づけ
resource "aws_api_gateway_base_path_mapping" "main" {
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.main.domain_name
}
