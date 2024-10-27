################################################################################
# S3 bucket
################################################################################
# 汎用S3バケット定義
resource "aws_s3_bucket" "codepipeline" {
  bucket = "${local.service_group}-${local.name}-codepipeline-${var.environment}"
}
