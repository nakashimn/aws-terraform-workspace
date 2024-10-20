################################################################################
# Role
################################################################################
# Codebuild用タスクロール
resource "aws_iam_role" "codebuild" {
  name = "CodeBuildRole-${substr(var.repository_name, 0, 50)}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "codebuild.amazonaws.com" }
  )
  managed_policy_arns = [
    aws_iam_policy.codebuild_role.arn
  ]
}

################################################################################
# Policy
################################################################################
# CodeBuild用ポリシー
resource "aws_iam_policy" "codebuild_role" {
  name = "CodebuildPolicy-${substr(var.repository_name, 0, 48)}"
  policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Effect" = "Allow",
          "Action" = [
            "ecr:*",
            "logs:*"
          ],
          "Resource" : "*"
        },
      ]
    }
  )
}
