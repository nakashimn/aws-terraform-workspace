################################################################################
# S3 bucket
################################################################################
resource "aws_s3_bucket" "terraform" {
  bucket = "nakashimn-terraform"
}

resource "aws_s3_bucket" "documents" {
  bucket                 = "nakashimn-documents"
}

resource "aws_s3_bucket_website_configuration" "documents" {
  bucket = aws_s3_bucket.documents.bucket
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket                  = aws_s3_bucket.documents.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "documents" {
  bucket = aws_s3_bucket.documents.id
  policy = data.aws_iam_policy_document.documents.json
}

data "aws_iam_policy_document" "documents" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
        "s3:GetObject"
    ]
    resources = [
        "${aws_s3_bucket.documents.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.documents.arn]
    }
  }
}
