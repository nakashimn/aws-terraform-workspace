# サービスグループ定義
vendor    = "nakashimn"
countory  = "jp"
service   = "templates"

# 環境設定
environment    = "dev"
region         = "ap-northeast-1"
vpc_cidr       = "172.16.0.0/16"

# アプリケーション設定
app_version            = "develop"
build_branch           = "develop"
rollback_grace_minutes = 0
container_port         = 3000
open_port              = 443
endpoint_domain        = "nakashimn.click"
autoscaling_config = {
  "min_capacity": 1,
  "max_capacity": 4
}

api_endpoint_url = "https://nakashimn.click"
