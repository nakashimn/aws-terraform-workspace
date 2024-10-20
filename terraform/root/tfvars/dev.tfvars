# サービスグループ定義
vendor    = "nakashimn"
countory  = "jp"
service   = "templates"

# 環境設定
environment = "dev"
region = "ap-northeast-3"
vpc_cidr  = "10.186.32.0/20"

allowed_ip_addresses = [
  "106.155.48.108/32"
]

open_ports  = [
  80, 443, 3000, 8000
]

resource_toggles = {
  enable_nat_gateway  = false
  enable_vpc_endpoint = false
}
