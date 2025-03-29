################################################################################
# Logger
################################################################################
# ECSサービス用Logger定義
resource "aws_cloudwatch_log_group" "main" {
  name              = "${local.service_group}-${local.name}-${var.environment}"
  retention_in_days = 30
}

# APIGateway用Logger定義
resource "aws_cloudwatch_log_group" "api_gateway" {
  name = "/${local.service_group}-api-gateway-${var.environment}/"
}
