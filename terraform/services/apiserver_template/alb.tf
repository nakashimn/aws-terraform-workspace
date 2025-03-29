################################################################################
# LoadBalancer
################################################################################
# ALBターゲットグループ定義
resource "aws_lb_target_group" "main" {
  # stg/pro環境のみBlue/Greenデプロイ用に2つ確保
  count = var.environment == "dev" ? 1 : 2

  name        = "${substr(local.name, 0, 29-local.len_suffix)}-${count.index}-${var.environment}"
  target_type = "ip"
  vpc_id      = data.aws_vpc.root.id
  port        = var.container_port
  protocol    = "HTTP"
  health_check {
    path                = "/api/status"
    interval            = 60
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 10
    matcher             = "200"
  }
}

# ALBリスナールール定義
resource "aws_lb_listener_rule" "main" {
  listener_arn = data.aws_lb_listener.main.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  lifecycle {
    ignore_changes = [ action ]
  }
}
