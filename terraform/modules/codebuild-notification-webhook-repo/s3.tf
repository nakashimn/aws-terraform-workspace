################################################################################
# S3
################################################################################
# CodePipeline用S3バケット定義
resource "aws_s3_bucket" "codepipeline" {
  bucket = "${substr(local.appname, 0, 36-local.len_suffix)}-codepipeline-${data.aws_caller_identity.current.id}-${var.environment}"
}

# CodePipeline用S3バケットのライフサイクルポリシー定義
resource "aws_s3_bucket_lifecycle_configuration" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id

  rule {
    id     = "Expired"
    status = "Enabled"

    expiration {
      days = 1
    }
    filter {}
  }
}
