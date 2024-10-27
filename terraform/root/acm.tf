################################################################################
# ACM
################################################################################
# サーバー証明書発行
resource "aws_acm_certificate" "main" {
  domain_name               = aws_route53_zone.main.name
  subject_alternative_names = ["*.${aws_route53_zone.main.name}"]
  validation_method         = "DNS"
}

# サーバー証明書の認証
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.main : record.fqdn]
}
