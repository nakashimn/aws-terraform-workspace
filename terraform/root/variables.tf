################################################################################
# Params
################################################################################
variable "allowed_ips_for_docs" { description = "ドキュメントへのアクセスを許可するIPアドレスのリスト" }
variable "allowed_ips_for_web" { description = "ウェブページへのアクセスを許可するIPアドレスのリスト" }
variable "country" { description = "国名" }
variable "resource_toggles" { description = "Resourceの有効/無効切替用変数" }
variable "endpoint_domain" { description = "エンドポイントのドメイン" }
variable "environment" { description = "環境(dev/stg/pro)" }
variable "n_availability_zone" { description = "AvailabilityZone数" }
variable "open_port" { description = "開放するポート" }
variable "profile" { description = "プロファイル名" }
variable "region" { description = "リージョン" }
variable "service" { description = "サービス名" }
variable "vendor" { description = "ベンダー名" }
variable "vpc_cidr" { description = "VPNのCIDRブロック" }
