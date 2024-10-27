################################################################################
# LocalParams
################################################################################
locals {
  # サービスグループ名
  service_group            = "${var.vendor}-${var.region}-${var.service}"
  # コンポーネント名称
  name                     = "openapi"
  # ECR設定
  repository_name          = "openapi_sample"
  # Bitbucket設定
  bitbucket_repository_name = "nakashimn/openapi_sample.git"
  bitbucket_repository_url  = "https://bitbucket.org/nakashimn/openapi_sample.git"
  version                   = "develop"
}
