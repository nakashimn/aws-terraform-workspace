################################################################################
# Role
################################################################################
resource "aws_iam_role" "ecs_anywhere" {
  name = "ECSAnywhereRole-${local.name}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "ecs.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
}
