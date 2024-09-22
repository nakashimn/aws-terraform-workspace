################################################################################
# Role
################################################################################
resource "aws_iam_role" "glue" {
  name = "GlueRole-${local.name}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "glue.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}
