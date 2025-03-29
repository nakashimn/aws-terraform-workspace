################################################################################
# LocalParams
################################################################################
locals {
  # サービスグループ名
  service_group            = "${var.vendor}-${var.region}-${var.service}"
  # コンポーネント名称
  name                     = "web"
  # ECR設定
  repository_name          = "webserver-template"
  # Bitbucket設定
  bitbucket_repository_name = "nakashimn/webserver-template"
  bitbucket_repository_url  = "https://bitbucket.org/nakashimn/webserver-template.git"
  version                   = "develop"
  # GitLab設定
  gitlab_repository_name = "nakashimn-trial/webserver-template"
  gitlab_repository_url  = "https://gitlab.com/nakashimn-trial/webserver-template.git"
  # suffixの長さ
  len_suffix = length(var.environment)
}
