################################################################################
# Role
################################################################################
# ECSAnywhere用ポリシー
resource "aws_iam_role" "ecs_anywhere" {
  name = "${local.service_group}-${local.name}-ECSAnywhereRole-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "ecs.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
}
