################################################################################
# LoadBalancer
################################################################################
# NLB定義
resource "aws_lb" "main" {
  name                             = "${substr(local.name, 0, 28)}-${var.environment}"
  load_balancer_type               = "network"
  internal                         = true
  subnets                          = data.aws_subnets.private.ids
  enable_cross_zone_load_balancing = true
}

# NLBターゲットグループ定義
resource "aws_lb_target_group" "main" {
  # stg/pro環境のみBlue/Greenデプロイ用に2つ確保
  count = var.environment == "dev" ? 1 : 2

  name        = "${substr(local.name, 0, 26)}-${count.index}-${var.environment}"
  target_type = "ip"
  vpc_id      = data.aws_vpc.root.id
  port        = var.container_port
  protocol    = "TCP"
  health_check {
    port                = "traffic-port"
    protocol            = "TCP"
    interval            = 15
    timeout             = 15
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# NLBリスナー定義
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.open_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }

  lifecycle {
    ignore_changes = [
      default_action
    ]
  }
}

# NLB(debug用)定義
resource "aws_lb" "debug" {
  count = ((var.environment == "dev") && (var.resource_toggles.enable_debug_nlb)) ? 1 : 0

  name                             = "${substr(local.name, 0, 22)}-debug-${var.environment}"
  load_balancer_type               = "network"
  internal                         = false
  subnets                          = data.aws_subnets.public.ids
  security_groups                  = [ aws_security_group.nlb_debug[0].id ]
  enable_cross_zone_load_balancing = true
}

# NLB(debug用)ターゲットグループ定義
resource "aws_lb_target_group" "debug" {
  count = ((var.environment == "dev") && (var.resource_toggles.enable_debug_nlb)) ? 1 : 0

  name        = aws_lb.debug[0].name
  target_type = "ip"
  vpc_id      = data.aws_vpc.root.id
  port        = var.container_port
  protocol    = "TCP"
  health_check {
    port                = "traffic-port"
    protocol            = "TCP"
    interval            = 15
    timeout             = 15
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# NLB(debug用)リスナー定義
resource "aws_lb_listener" "debug" {
  count = ((var.environment == "dev") && (var.resource_toggles.enable_debug_nlb)) ? 1 : 0

  load_balancer_arn = aws_lb.debug[0].arn
  port              = var.open_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.debug[0].arn
  }
}
