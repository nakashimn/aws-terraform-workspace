variable "account_id" { description = "AWSAccountID" }
variable "codebuild_role" { description = "CodeBuild用ロール" }
variable "ecs_task_execution_role" { description = "タスク実行ロール" }
variable "ecs_task_role" { description = "タスクロール" }
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
variable "subnet_ids" { description = "利用するSubnetのIDのリスト" }
variable "vpc_id" { description = "利用するVPCのID" }
