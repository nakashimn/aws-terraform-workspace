################################################################################
# Params
################################################################################
variable "acceptable_method" { description = "受け付けるHTTPリクエストメソッドのリスト" }
variable "allowed_ip_addresses" { description = "アクセスを許可するIPアドレスのリスト" }
variable "autoscaling_config" { description = "AutoScalingの設定" }
variable "app_version" { description = "アプリのバージョン" }
variable "build_branch" { description = "ビルド対象ブランチ名" }
variable "container_port" { description = "コンテナの開放ポート" }
variable "countory" { description = "国名" }
variable "endpoint_domain" { description = "エンドポイントのドメイン" }
variable "environment" { description = "環境(dev/stg/pro)" }
variable "open_port" {
  default     = 80
  description = "NLBが受け付けるポート"
}
variable "region" { description = "利用するリージョン" }
variable "resource_toggles" { description = "Resourceの有効/無効切替用変数" }
variable "rollback_grace_minutes" { description = "デプロイのロールバック猶予時間[分]" }
variable "service" { description = "サービス名" }
variable "vendor" { description = "ベンダー名" }
variable "vpc_cidr" { description = "VPCのCIDRブロック" }
