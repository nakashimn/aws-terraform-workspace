################################################################################
# SecurityGroup
################################################################################
# SecurityGroup定義
resource "aws_security_group" "main" {
  name   = local.name
  vpc_id = data.aws_vpc.root.id

  egress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }
}
