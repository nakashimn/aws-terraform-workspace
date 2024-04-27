################################################################################
# Params
################################################################################
variable "acceptable_method" { description = "受け付けるHTTPリクエストメソッドのリスト" }
variable "container_port" { description = "コンテナの開放ポート" }
variable "open_port" {
  default     = 80
  description = "NLBが受け付けるポート"
}
variable "region" { description = "利用するリージョン" }

################################################################################
# LocalParams
################################################################################
locals {
  name            = "openapi-sample"
  repository_name = "openapi_sample"
  version         = "develop"
}
