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
resource "aws_api_gateway_method" "openapi_sample" {
  count         = length(var.acceptable_method)
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = var.acceptable_method[count.index]
  authorization = "NONE"
   request_parameters = {
    "method.request.path.proxy" = true
  }
}

# APIGatewayとNLBのDNSの紐づけ
resource "aws_api_gateway_integration" "openapi_sample" {
  count                   = length(aws_api_gateway_method.openapi_sample)
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.main.id
  http_method             = aws_api_gateway_method.openapi_sample[count.index].http_method
  integration_http_method = aws_api_gateway_method.openapi_sample[count.index].http_method
  type                    = "HTTP_PROXY"
  uri                     = "http://${module.openapi_sample.aws_lb.dns_name}/{proxy}"
  cache_key_parameters = ["method.request.path.proxy"]
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy" # Proxy統合有効化
  }

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.openapi_sample.id
}

# APIGatewayとアクセス制御用Policyの紐づけ
resource "aws_api_gateway_rest_api_policy" "internal" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  policy      = data.aws_iam_policy_document.api_gateway.json
}

# APIGatewayとVPCLinkの紐づけ
resource "aws_api_gateway_vpc_link" "openapi_sample" {
  name        = "api-gateway-vpc-link-openapi-sample"
  target_arns = [module.openapi_sample.aws_lb.arn]
}

# APIGatewayデプロイ定義
resource "aws_api_gateway_deployment" "openapi_sample" {
  depends_on    = [aws_api_gateway_integration.openapi_sample]

  rest_api_id   = aws_api_gateway_rest_api.main.id
  triggers      = {
    redeployment = sha1(
      jsonencode(
        [
          aws_api_gateway_resource.main.id,
          aws_api_gateway_method.openapi_sample.*.id,
          aws_api_gateway_integration.openapi_sample.*.id,
        ]
      )
    )
  }
}

# APIデプロイ先Stage定義
resource "aws_api_gateway_stage" "openapi_sample" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.openapi_sample.id
  stage_name = "develop"

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
