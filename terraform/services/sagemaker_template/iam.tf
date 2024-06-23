################################################################################
# Role
################################################################################
resource "aws_iam_role" "sagemaker_notebook" {
  name = "SageMakerNotebookRole-${local.name}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "sagemaker.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
  ]
}
