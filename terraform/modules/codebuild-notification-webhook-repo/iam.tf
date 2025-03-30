################################################################################
# Role
################################################################################
# CodePipeline用ロール
resource "aws_iam_role" "codepipeline" {
  name = "${substr("${local.appname}-CodePipeline", 0, 63-local.len_suffix)}-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "codebuild.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess",
    "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess",
    "arn:aws:iam::aws:policy/AWSCodeDeployDeployerAccess",
    "arn:aws:iam::aws:policy/service-role/AWSCodeStarServiceRole"
  ]
}

# CodeBuild用ロール
resource "aws_iam_role" "codebuild" {
  name = "${substr("${local.appname}-CodeBuild", 0, 63-local.len_suffix)}-${var.environment}"
  assume_role_policy = templatefile(
    "${path.module}/assets/templates/assume_role_policy.tpl",
    { principal = "codebuild.amazonaws.com" }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess",
    "arn:aws:iam::aws:policy/AWSLambda_FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
}
