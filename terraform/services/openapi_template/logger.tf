################################################################################
# Logger
################################################################################
# ECSサービス用Logger定義
resource "aws_cloudwatch_log_group" "main" {
  name              = "${local.service_group}-${local.name}-${var.environment}"
  retention_in_days = 30
}
