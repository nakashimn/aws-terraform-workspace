################################################################################
# LocalParams
################################################################################
locals {
  # サービスグループ名
  service_group            = "${var.vendor}-${var.region}-${var.service}"
  # コンポーネント名称
  name                     = "apiserver"
  # ECR設定
  repository_name          = "apiserver-template"
  # Bitbucket設定
  bitbucket_repository_name = "nakashimn/apiserver-template"
  bitbucket_repository_url  = "https://bitbucket.org/nakashimn/apiserver-template.git"
  version                   = "develop"
  # GitLab設定
  gitlab_repository_name = "nakashimn-trial/apiserver-template"
  gitlab_repository_url  = "https://gitlab.com/nakashimn-trial/apiserver-template.git"
  # suffixの長さ
  len_suffix = length(var.environment)
}
