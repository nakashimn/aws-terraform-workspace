################################################################################
# Params
################################################################################
variable "acceptable_method" { description = "受け付けるHTTPリクエストメソッドのリスト" }
variable "container_port" { description = "コンテナの開放ポート" }
variable "environment" { description = "環境(dev/stg/pro)" }
variable "open_port" {
  default     = 80
  description = "NLBが受け付けるポート"
}
variable "region" { description = "利用するリージョン" }
