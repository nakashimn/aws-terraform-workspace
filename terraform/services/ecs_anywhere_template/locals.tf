################################################################################
# LocalParams
################################################################################
locals {
  # サービスグループ名
  service_group   = "${var.vendor}-${var.countory}-${var.service}"
  # コンポーネント名称
  name            = "ecs-anywhere-template"
  # ECRリポジトリ名
  repository_name = "ecs-anywhere-template"
  #
  version         = "develop"
}
