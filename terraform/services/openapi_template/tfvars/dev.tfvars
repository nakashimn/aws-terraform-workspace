# サービスグループ定義
vendor    = "nakashimn"
countory  = "jp"
service   = "templates"

# 環境設定
environment    = "dev"
region         = "ap-northeast-1"
vpc_cidr       = "172.16.0.0/16"

# アプリケーション設定
app_version       = "develop"
build_branch      = "develop"
acceptable_method = [
  "GET",
  "POST"
]
container_port = 3000
open_port      = 80

allowed_ip_addresses = [
  "59.132.67.108/32"
]

resource_toggles = {
  enable_debug_nlb  = false
}

endpoint_domain = "nakashimn.click"
