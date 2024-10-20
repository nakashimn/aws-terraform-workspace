################################################################################
# Repository
################################################################################
# ECRリポジトリ定義
resource "aws_ecr_repository" "main" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECRリポジトリとライフサイクルポリシーの紐づけ
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = templatefile(
    "${path.module}/assets/templates/ecr_lifecycle_policy.tpl",
    {period_days = 14}
  )
}
