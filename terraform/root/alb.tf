################################################################################
# LoadBalancer
################################################################################
# ALB定義
resource "aws_lb" "main" {
  name                             = "${local.service_group}-${var.environment}"
  load_balancer_type               = "application"
  internal                         = false
  subnets                          = aws_subnet.public[*].id
  security_groups                  = [ aws_security_group.alb.id ]
  enable_cross_zone_load_balancing = true
}

# ALBリスナー定義(Default Action)
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port = var.open_port
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn = aws_acm_certificate.main.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = 404
      content_type = "text/plain"
      message_body = "404 Not Found"
    }
  }

  lifecycle {
    ignore_changes = [ default_action ]
  }
}
