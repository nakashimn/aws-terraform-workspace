################################################################################
# APIGateway
################################################################################
# APIGatewayとNLBのDNSの紐づけ
resource "aws_api_gateway_integration" "main" {
  count                   = length(aws_api_gateway_method.main)
  rest_api_id             = aws_api_gateway_rest_api.main.id
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
  name        = "api-gateway-vpc-link-openapi-sample"
  target_arns = [aws_lb.main.arn]
}
