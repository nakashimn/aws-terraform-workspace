################################################################################
# SecurityGroup
################################################################################
# ECS用SecurityGroup定義
resource "aws_security_group" "main" {
  name   = "${local.service_group}-${local.name}-sg-${var.environment}"
  vpc_id = data.aws_vpc.root.id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  }
}
