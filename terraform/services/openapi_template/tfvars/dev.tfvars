# サービスグループ定義
vendor    = "nakashimn"
countory  = "jp"
service   = "templates"

# 環境設定
environment    = "dev"
region         = "ap-northeast-3"
vpc_cidr       = "10.186.32.0/20"

# アプリケーション設定
app_version       = "develop"
build_branch      = "develop"
acceptable_method = [
  "GET",
  "POST"
]
container_port = 3000
open_port      = 80
