################################################################################
# LocalParams
################################################################################
locals {
  # サービスグループ名
  service_group            = "${var.vendor}-${var.countory}-${var.service}"
  # コンポーネント名称
  name                     = "lambda"
  # ECR設定
  repository_name          = "lambda-py-template"
  # Github設定
  github_repository_url    = "https://github.com/nakashimn/lambda-py-template.git"
  version                  = "develop"
}
