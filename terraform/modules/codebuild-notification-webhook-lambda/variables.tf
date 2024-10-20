################################################################################
# Params
################################################################################
variable "codebuild_notification_repo_url" { description = "CodeBuild-NotificationのECRリポジトリ名" }
variable "codebuild_project_name" { description = "対象のCodeBuildプロジェクト名" }
variable "region" { description = "利用するリージョン" }
variable "webhook_url" { description = "webhookのURL" }

variable "in_progress_message" {
    default     = "ビルドを開始しました。"
    description = "ビルド開始時のメッセージ"
}
variable "succeeded_message" {
    default     = "ビルドが成功しました！"
    description = "ビルド成功時のメッセージ"
}
variable "failed_message" {
    default     = "ビルドが失敗しました..."
    description = "ビルド失敗時のメッセージ"
}
