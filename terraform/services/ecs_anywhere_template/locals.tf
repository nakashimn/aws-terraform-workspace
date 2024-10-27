################################################################################
# LocalParams
################################################################################
locals {
  # サービスグループ名
  service_group   = "${var.vendor}-${var.region}-${var.service}"
  # コンポーネント名称
  name            = "ecs-anywhere"
  # ECRリポジトリ名
  repository_name = "ecs-anywhere-template"
  #
  version         = "develop"
}
