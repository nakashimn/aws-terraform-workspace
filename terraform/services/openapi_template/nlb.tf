################################################################################
# LoadBalancer
################################################################################
resource "aws_lb" "main" {
  name               = "alb-openapi-sample"
  load_balancer_type = "network"
  internal           = true
  subnets            = data.aws_subnets.public.ids
}

resource "aws_lb_target_group" "main" {
  name        = "openapi-sample"
  target_type = "ip"
  vpc_id      = data.aws_vpc.root.id
  port        = var.container_port
  protocol    = "TCP"
  health_check {
    port                = "traffic-port"
    protocol            = "TCP"
    interval            = 60
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.open_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
