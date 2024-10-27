################################################################################
# LocalParams
################################################################################
locals {
  # サービスグループ名
  service_group            = "${var.vendor}-${var.region}-${var.service}"
  # コンポーネント名称
  name                     = "ecs-batch"
  # ECR設定
  repository_name          = "ecs_dev_py_template"
  # Bitbucket設定
  bitbucket_repository_url = "https://x-token-auth:${data.aws_ssm_parameter.main.value}@bitbucket.org/nakashimn/ecs_dev_py_template.git"
  version                  = "develop"
}
