variable "account_id" { description = "AWSAccountID" }
variable "codebuild_role" { description = "CodeBuild用ロール" }
variable "ecs_task_execution_role" { description = "タスク実行ロール" }
variable "ecs_task_role" { description = "タスクロール" }
variable "health_check_path" {
  default     = "/api/v1/hello"
  description = "healthcheck用のpath ステータスコード:200のレスポンスを期待する"
}
variable "port" {
  default     = 3000
  description = "HTTPリクエストを受け付けるポート"
}
variable "region" { description = "利用するリージョン" }
variable "subnet_ids" { description = "利用するSubnetのIDのリスト" }
variable "security_group_ids" { description = "利用するSecurityGroupのIDのリスト" }
variable "vpc_id" { description = "利用するVPCのID" }
