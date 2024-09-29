################################################################################
# Lambda                                                                       #
################################################################################
resource "aws_lambda_function" "main" {
  function_name = "lambda_ts_tamplate"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.main.repository_url}:${var.build_branch}"
  role          = aws_iam_role.lambda.arn
  publish       = true

  memory_size = 128
  timeout     = 30

  lifecycle {
    ignore_changes = [
      image_uri, last_modified
    ]
  }
}
