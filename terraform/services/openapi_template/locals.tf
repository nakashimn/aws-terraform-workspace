################################################################################
# LocalParams
################################################################################
locals {
  # サービスグループ名
  service_group   = "${var.vendor}-${var.countory}-${var.service}"
  # コンポーネント名称
  name            = "openapi-sample"
  # ECRリポジトリ名
  repository_name = "openapi_sample"
  #
  version         = "develop"
}
