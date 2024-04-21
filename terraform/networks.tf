################################################################################
# VPC
################################################################################
# VPC定義
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
}

################################################################################
# PublicSubnets
################################################################################
# PublicSubnet定義
resource "aws_subnet" "public" {
  count  = length(local.availability_zones) # AvailabilityZoneの数だけ生成
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(
    aws_vpc.main.cidr_block,
    2 * length(local.availability_zones), # (public, private) x availability_zone数
    count.index
  )
  availability_zone       = local.availability_zones[count.index].name
  map_public_ip_on_launch = true
  tags = {
    Name = "nakashimn-terraform-public-${local.availability_zones[count.index].zone_id}"
  }
}

# PublicRoutingTable定義
resource "aws_route_table" "public" {
  count  = length(aws_subnet.public)
  vpc_id = aws_vpc.main.id

  # InternetGatewayと紐づけ
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "route-table-public-${count.index}"
  }
}

# PublicRoutingTableとPublicSubnetの紐づけ
resource "aws_route_table_association" "public" {
  count          = length(local.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

################################################################################
# PrivateSubnets
################################################################################
# PrivateSubnet定義
resource "aws_subnet" "private" {
  count  = length(local.availability_zones) # AvailabilityZoneの数だけ生成
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(
    aws_vpc.main.cidr_block,
    2 * length(local.availability_zones), # (public, private) x availability_zone数
    count.index + length(local.availability_zones)
  )
  availability_zone       = local.availability_zones[count.index].name
  map_public_ip_on_launch = false
  tags = {
    Name = "nakashimn-terraform-private-${local.availability_zones[count.index].zone_id}"
  }
}

# PrivateRoutingTable定義
resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.main.id

  # NATGatewayと紐づけ
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "route-table-private-${count.index}"
  }
}

# PrivateRoutingTableとPrivateSubnetの紐づけ
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

################################################################################
# SecurityGroup
################################################################################
# SecurityGroup定義
resource "aws_security_group" "main" {
  name   = "terraform-security-group"
  vpc_id = aws_vpc.main.id
}

# SecurityGroupRule(ssh接続用インバウンドルール)定義
resource "aws_security_group_rule" "ingress_ssh" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ip_addresses
}

# SecurityGroupRule(外部向けインバウンドルール)定義
resource "aws_security_group_rule" "ingress" {
  count             = length(var.open_ports)
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  from_port         = var.open_ports[count.index]
  to_port           = var.open_ports[count.index]
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

################################################################################
# InternetGateway
################################################################################
# InternetGateway定義
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

################################################################################
# NATGateway
################################################################################
#NATGateway定義
resource "aws_nat_gateway" "main" {
  count         = length(aws_subnet.public)
  allocation_id = aws_eip.nat_gateway[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-gateway-terraform-${count.index}"
  }
}

# NATGateway用ElasticIP定義
resource "aws_eip" "nat_gateway" {
  count = length(aws_subnet.public)

  tags = {
    Name = "elastic-ip-${count.index}"
  }
}
