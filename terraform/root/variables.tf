################################################################################
# Params
################################################################################
variable "allowed_ip_addresses" { description = "アクセスを許可するIPアドレスのリスト" }
variable "cidr_block" { description = "VPNのCIDRブロック" }
variable "environment" { description = "環境(dev/stg/pro)" }
variable "open_ports" { description = "開放ポートのリスト" }
variable "region" { description = "リージョン" }

################################################################################
# LocalParams
################################################################################
locals {
  # AWSアベイラビリティゾーンの情報
  availability_zones = [
    for index, name in data.aws_availability_zones.available.names :
    {
      name    = name
      zone_id = data.aws_availability_zones.available.zone_ids[index]
    }
  ]
}
