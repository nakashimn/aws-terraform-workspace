allowed_ip_addresses = [
  "106.155.48.108/32"
]
cidr_block  = "10.186.32.0/20"
environment = "dev"
open_ports  = [
  80, 443, 3000, 8000
]
region = "ap-northeast-3"

resource_toggles = {
  enable_nat_gateway = false
}
