################################################################################
# SecurityGroup
################################################################################

resource "aws_security_group" "main" {
  name   = local.name
  vpc_id = data.aws_vpc.root.id
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
