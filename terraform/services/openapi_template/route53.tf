
################################################################################
# Route53
################################################################################
# Route53ゾーン定義
resource "aws_route53_zone" "main" {
  name = "api.nakashimn.click"
}

# Route53レコード登録
resource "aws_route53_record" "main" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

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

# APIGatewayのエイリアス登録
resource "aws_route53_record" "api_gateway_alias" {
  name    = aws_api_gateway_domain_name.main.domain_name
  type    = "A"
  zone_id = aws_route53_zone.main.id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.main.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.main.regional_zone_id
  }
}
