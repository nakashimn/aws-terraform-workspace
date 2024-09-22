################################################################################
# SageMaker
################################################################################
resource "aws_sagemaker_notebook_instance" "main" {
  name = "${local.service_group}-${local.name}-nootbook-${var.environment}"
  instance_type = "ml.t3.medium"
  role_arn = aws_iam_role.sagemaker_notebook.arn
}
