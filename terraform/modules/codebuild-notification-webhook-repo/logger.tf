################################################################################
# Logger
################################################################################
# Codebuild用ロガー
resource "aws_cloudwatch_log_group" "main" {
  name              = "codebuild-${var.repository_name}"
  retention_in_days = 30
}
