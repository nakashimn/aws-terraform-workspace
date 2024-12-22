################################################################################
# LocalParams
################################################################################
locals {
  # サービスグループ名
  service_group            = "${var.vendor}-${var.region}-${var.service}"
  # コンポーネント名称
  name                     = "openapi"
  # ECR設定
  repository_name          = "openapi-template"
  # Bitbucket設定
  bitbucket_repository_name = "nakashimn/openapi-template"
  bitbucket_repository_url  = "https://bitbucket.org/nakashimn/openapi-template.git"
  version                   = "develop"
  # GitLab設定
  gitlab_repository_name = "nakashimn-trial/openapi-template"
  gitlab_repository_url  = "https://gitlab.com/nakashimn-trial/openapi-template.git"
}
