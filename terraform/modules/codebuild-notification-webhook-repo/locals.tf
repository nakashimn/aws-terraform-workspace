################################################################################
# Locals
################################################################################
locals {
  # アプリ名
  appname = "bldnotif-${substr(var.service, 0, 55)}"
  # リポジトリ名
  repository_name = ""
  # suffixの長さ
  len_suffix = length(var.environment)
}
