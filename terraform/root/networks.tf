################################################################################
# VPC
################################################################################
# VPC定義
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${local.service_group}-vpc-${var.environment}"
  }
}

################################################################################
# PublicSubnets
################################################################################
# PublicSubnet定義
resource "aws_subnet" "public" {
  count  = var.environment == "dev" ? 1 : length(local.availability_zones) # AvailabilityZoneの数だけ生成
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(
    aws_vpc.main.cidr_block,
    2 * length(local.availability_zones), # (public, private) x availability_zone数
    count.index
  )
  availability_zone       = local.availability_zones[count.index].name
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.service_group}-subnet-public-${var.environment}-${local.availability_zones[count.index].zone_id}"
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
    Name = "${local.service_group}-route-table-public-${var.environment}-${count.index}"
  }
}

# PublicRoutingTableとPublicSubnetの紐づけ
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

################################################################################
# PrivateSubnets
################################################################################
# PrivateSubnet定義
resource "aws_subnet" "private" {
  count  = var.environment == "dev" ? 1 : length(local.availability_zones) # AvailabilityZoneの数だけ生成
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(
    aws_vpc.main.cidr_block,
    2 * length(local.availability_zones), # (public, private) x availability_zone数
    count.index + length(local.availability_zones)
  )
  availability_zone       = local.availability_zones[count.index].name
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.service_group}-subnet-private-${var.environment}-${local.availability_zones[count.index].zone_id}"
  }
}

# PrivateRoutingTable定義
resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.main.id

  # NATGatewayと紐づけ
  dynamic "route" {
    for_each = var.resource_toggles.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.environment == "pro" ? aws_nat_gateway.main[count.index].id : aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "${local.service_group}-route-table-private-${count.index}"
  }
}

# PrivateRoutingTableとPrivateSubnetの紐づけ
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
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
  count         = var.resource_toggles.enable_nat_gateway ? (var.environment == "pro" ? length(aws_subnet.public) : 1) : 0
  allocation_id = aws_eip.nat_gateway[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.service_group}-nat-gateway-${var.environment}-${count.index}"
  }
}

# NATGateway用ElasticIP定義
resource "aws_eip" "nat_gateway" {
  count = var.resource_toggles.enable_nat_gateway ? (var.environment == "pro" ? length(aws_subnet.public) : 1) : 0

  tags = {
    Name = "${local.service_group}-elastic-ip-${var.environment}-${count.index}"
  }
}
