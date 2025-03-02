################################################################################
# APIGateway
################################################################################
# APIGatewayとNLBのDNSの紐づけ
resource "aws_api_gateway_integration" "main" {
  count = length(aws_api_gateway_method.main)

  rest_api_id             = data.aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.main.id
  http_method             = aws_api_gateway_method.main[count.index].http_method
  integration_http_method = aws_api_gateway_method.main[count.index].http_method
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.main.dns_name}/{proxy}"
  cache_key_parameters    = ["method.request.path.proxy"]
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy" # Proxy統合有効化
  }

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.main.id
}

# APIGatewayのリソース定義
resource "aws_api_gateway_resource" "main" {
  rest_api_id = data.aws_api_gateway_rest_api.main.id
  parent_id   = data.aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# HTTPリクエストメソッド定義
resource "aws_api_gateway_method" "main" {
  count         = length(var.acceptable_method)
  rest_api_id   = data.aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = var.acceptable_method[count.index]
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# APIGatewayとVPCLinkの紐づけ
resource "aws_api_gateway_vpc_link" "main" {
  name        = "${local.service_group}-${local.name}-api-gateway-vpc-link-${var.environment}"
  target_arns = [aws_lb.main.arn]
}

# APIGatewayデプロイ定義
resource "aws_api_gateway_deployment" "main" {

  rest_api_id = data.aws_api_gateway_rest_api.main.id
  triggers = {
    redeployment = sha1(
      jsonencode(
        []
      )
    )
  }

  depends_on = [ aws_api_gateway_integration.main, aws_api_gateway_method.main ]
}

# APIデプロイ先Stage定義
resource "aws_api_gateway_stage" "main" {
  rest_api_id   = data.aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.main.id
  stage_name    = var.environment == "pro" ? local.name : "${local.name}-${var.environment}"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format          = replace(file("${path.module}/assets/logformat/api_gateway.json"), "\n", "")
  }
}

# APIGatewayとカスタムドメインの紐づけ
resource "aws_api_gateway_base_path_mapping" "main" {
  api_id      = data.aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = data.aws_api_gateway_domain_name.main.domain_name
  base_path   = "api"
}
