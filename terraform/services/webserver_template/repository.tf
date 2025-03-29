################################################################################
# Repository
################################################################################
# ECR定義
resource "aws_ecr_repository" "main" {
  name                 = local.repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECRライフサイクルポリシー
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = templatefile(
    "${path.module}/assets/templates/ecr_lifecycle_policy.tpl",
    {period_days = 14}
  )
}
