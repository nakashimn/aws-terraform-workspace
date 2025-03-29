# サービスグループ定義
vendor  = "nakashimn"
region  = "ap-northeast-1"
service = "templates"

# 環境設定
country     = "jp"
vpc_cidr    = "172.16.0.0/20"
profile     = "terraform"
environment = "dev"

n_availability_zone = 1

allowed_ips_for_web = []
allowed_ips_for_docs = []

resource_toggles = {
  enable_nat_gateway  = false
  enable_vpc_endpoint = false
}

open_port       = 443
endpoint_domain = "nakashimn.click"
