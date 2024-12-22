################################################################################
# Route53
################################################################################
# debug用NLBのalias登録(publicアクセス可)
resource "aws_route53_record" "nlb_alias" {
  count = ((var.environment == "dev") && (var.resource_toggles.enable_debug_nlb)) ? 1 : 0

  name    = "debug.${var.endpoint_domain}"
  type    = "A"
  zone_id = data.aws_route53_zone.main.id

  alias {
    evaluate_target_health = true
    name                   = aws_lb.debug[0].dns_name
    zone_id                = aws_lb.debug[0].zone_id
  }
}

# Route53レコード登録
resource "aws_route53_record" "private" {
  zone_id = data.aws_route53_zone.private.id
  name    = data.aws_route53_zone.private.name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = false
  }
}
