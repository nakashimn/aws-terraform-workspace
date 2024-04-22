################################################################################
# APIGateway
################################################################################
# APIGateway定義
resource "aws_api_gateway_rest_api" "main" {
  name = "aws-api-gateway-terraform"
}

# APIGatewayのリソース定義
resource "aws_api_gateway_resource" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# HTTPリクエストメソッド定義
resource "aws_api_gateway_method" "main" {
  count         = length(var.acceptable_method)
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = var.acceptable_method[count.index]
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
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
        [
          aws_api_gateway_resource.main.id,
          aws_api_gateway_method.main.*.id
        ]
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
