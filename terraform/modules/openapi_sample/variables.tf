variable "health_check_path" {
  default     = "/api/v1/hello"
  description = "healthcheck用のpath ステータスコード:200のレスポンスを期待する"
}
variable "container_port" { description = "コンテナの開放ポート" }
variable "open_port" {
  default     = 80
  description = "NLBが受け付けるポート"
}
variable "region" { description = "利用するリージョン" }
