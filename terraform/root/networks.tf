################################################################################
# VPC
################################################################################
# VPC定義
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

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

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 3, count.index) # 2^3分割を想定
  availability_zone       = local.availability_zones[count.index].name
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.service_group}-public-${var.environment}-${local.availability_zones[count.index].zone_id}"
    Type = "${var.environment},public"
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
    Name = "${local.service_group}-public-${var.environment}-${count.index}"
  }
}

# PublicRoutingTableとPublicSubnetの紐づけ
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

################################################################################
# PrivateSubnets
################################################################################
# PrivateSubnet定義
resource "aws_subnet" "private" {
  count = var.environment == "dev" ? 1 : length(local.availability_zones) # AvailabilityZoneの数だけ生成

  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 3,count.index + length(local.availability_zones)) # 2^3分割を想定
  availability_zone       = local.availability_zones[count.index].name
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.service_group}-private-${var.environment}-${local.availability_zones[count.index].zone_id}"
    Type = "${var.environment},private"
  }
}

# PrivateRoutingTable定義
resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.main.id

  # NATGatewayと紐づけ
  dynamic "route" {
    for_each = var.resource_toggles.enable_nat_gateway ? [true] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "${local.service_group}-private-${var.environment}-${count.index}"
  }
}

# PrivateRoutingTableとPrivateSubnetの紐づけ
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

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
  count = var.resource_toggles.enable_nat_gateway ? 1 : 0 # 基本は1つ

  allocation_id = aws_eip.nat_gateway[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.service_group}-${var.environment}-${count.index}"
  }
}

# NATGateway用ElasticIP定義
resource "aws_eip" "nat_gateway" {
  count = var.resource_toggles.enable_nat_gateway ? 1 : 0 # 基本は1つ

  tags = {
    Name = "${local.service_group}-nat-gateway-${var.environment}-${count.index}"
  }
}

################################################################################
# PrivateLink
################################################################################
resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.resource_toggles.enable_vpc_endpoint ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.private_link.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.resource_toggles.enable_vpc_endpoint ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.private_link.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "logs" {
  count = var.resource_toggles.enable_vpc_endpoint ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.private_link.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  count = var.resource_toggles.enable_vpc_endpoint ? 1 : 0

  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.main.id
  route_table_ids = aws_route_table.private[*].id
}
