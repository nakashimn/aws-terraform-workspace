################################################################################
# SecurityGroup
################################################################################
# SecurityGroup定義
resource "aws_security_group" "main" {
  name   = local.name
  vpc_id = data.aws_vpc.root.id
}

# SecurityGroupRule(外部向けインバウンドルール)定義
resource "aws_security_group_rule" "ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  from_port         = var.container_port
  to_port           = var.container_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# SecurityGroupRule(アウトバウンドルール)定義
resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
