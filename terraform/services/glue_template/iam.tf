################################################################################
# Role
################################################################################
# Glue実行ロール
resource "aws_iam_role" "glue" {
  name = "${local.service_group}-${local.name}-GlueRole-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "glue.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}
