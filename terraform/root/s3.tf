################################################################################
# S3 bucket
################################################################################
# 汎用S3バケット定義
resource "aws_s3_bucket" "terraform" {
  bucket = "${local.service_group}-terraform-${var.environment}"
}

# ドキュメントホスティング用S3バケット定義
resource "aws_s3_bucket" "documents" {
  bucket = "${local.service_group}-documents-${var.environment}"
}

# S3バケットの静的ホスティング設定
resource "aws_s3_bucket_website_configuration" "documents" {
  bucket = aws_s3_bucket.documents.bucket
  index_document {
    suffix = "index.html"
  }
}

# S3バケットのポリシー紐づけ
resource "aws_s3_bucket_policy" "documents" {
  bucket = aws_s3_bucket.documents.id
  policy = data.aws_iam_policy_document.documents.json
}

# S3バケットのCloudFront接続許可ポリシー定義
data "aws_iam_policy_document" "documents" {
  statement {
    effect = "Allow"
    actions = [
        "s3:GetObject"
    ]
    resources = [
        "${aws_s3_bucket.documents.arn}/*"
    ]
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.allowed_ips_for_docs
    }
  }
}
