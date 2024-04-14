variable "region" { description = "利用するリージョン" }
variable "ecs_task_execution_role" { description = "タスク実行ロール" }
variable "ecs_task_role" { description = "タスクロール" }
variable "eventbridge_scheduler_role" { description = "スケジューラのロール"}
variable "subnet_ids" { description = "利用するSubnetのIDのリスト" }
variable "security_group_ids" { description = "利用するSecurityGroupのIDのリスト" }
variable "vpc_id" { description = "利用するVPCのID" }
