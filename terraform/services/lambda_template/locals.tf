################################################################################
# LocalParams
################################################################################
locals {
  # サービスグループ名
  service_group            = "${var.vendor}-${var.countory}-${var.service}"
  # コンポーネント名称
  name                     = "lambda"
  # ECR設定
  repository_name          = "lambda_ts_template"
  # Github設定
  github_repository_url    = "https://github.com/nakashimn/lambda_template.git"
  version                  = "develop"
}
