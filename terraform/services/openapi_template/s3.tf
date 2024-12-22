################################################################################
# S3 bucket
################################################################################
# 汎用S3バケット定義
resource "aws_s3_bucket" "codepipeline" {
  bucket = "${local.service_group}-${local.name}-codepipeline-${var.environment}"
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.codepipeline.id

  rule {
    id     = "expired"
    status = "Enabled"

    expiration {
      days = 1
    }
    filter {}
  }
}
