# サービスグループ定義
vendor    = "nakashimn"
countory  = "jp"
service   = "templates"

# 環境設定
environment = "dev"
region = "ap-northeast-1"
vpc_cidr  = "172.16.0.0/16"

allowed_ip_addresses = [
  "59.132.67.108/32"
]

open_ports  = [
  80, 443, 3000, 8000
]

resource_toggles = {
  enable_nat_gateway  = true
  enable_vpc_endpoint = false
}

endpoint_domain = "nakashimn.click"
