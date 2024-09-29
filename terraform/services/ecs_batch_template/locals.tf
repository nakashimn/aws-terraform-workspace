################################################################################
# LocalParams
################################################################################
locals {
  # サービスグループ名
  service_group            = "${var.vendor}-${var.countory}-${var.service}"
  # コンポーネント名称
  name                     = "ecs-batch"
  # ECR設定
  repository_name          = "ecs_dev_py_template"
  # Bitbucket設定
  bitbucket_repository_url = "https://x-token-auth:${var.bitbucket_access_token}@bitbucket.org/nakashimn/ecs_dev_py_template.git"
  version                  = "develop"
}
