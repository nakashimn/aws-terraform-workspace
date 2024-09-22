################################################################################
# Role
################################################################################
# SagemakerNotebook用ロール
resource "aws_iam_role" "sagemaker_notebook" {
  name = "${local.service_group}-${local.name}-SageMakerNotebookRole-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "sagemaker.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
  ]
}
