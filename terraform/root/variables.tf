################################################################################
# Params
################################################################################
variable "allowed_ip_addresses" { description = "アクセスを許可するIPアドレスのリスト" }
variable "countory" { description = "国名" }
variable "resource_toggles" { description = "Resourceの有効/無効切替用変数" }
variable "endpoint_domain" { description = "エンドポイントのドメイン" }
variable "environment" { description = "環境(dev/stg/pro)" }
variable "open_ports" { description = "開放ポートのリスト" }
variable "profile" { description = "プロファイル名" }
variable "region" { description = "リージョン" }
variable "service" { description = "サービス名" }
variable "vendor" { description = "ベンダー名" }
variable "vpc_cidr" { description = "VPNのCIDRブロック" }
