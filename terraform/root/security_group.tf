################################################################################
# SecurityGroup
################################################################################
# VPCEndpoint向けSecurityGroup定義(ECR, Logs)
resource "aws_security_group" "private_link" {
  name   = "${local.service_group}-sg-vpce-ecr-${var.environment}"
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

# VPCEndpoint向けSecurityGroup定義(PrivateAPIGateway)
resource "aws_security_group" "api_gateway" {
  name   = "${local.service_group}-sg-vpce-apigw-${var.environment}"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["10.0.0.0/8"]
  }

  egress {
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  }
}
