################################################################################
# SecurityGroup
################################################################################
# SecurityGroup定義
resource "aws_security_group" "private_link" {
  name   = "${local.service_group}-sg-${var.environment}"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = [aws_vpc.main.cidr_block]
  }

  egress {
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  }

}
