################################################################################
# VPC
################################################################################
# VPC定義
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  tags = {
    name = "terraform"
  }
}

################################################################################
# PublicSubnets
################################################################################
# PublicSubnet定義
resource "aws_subnet" "public" {
  count  = var.environment == "pro" ? length(local.availability_zones) : 1 # pro環境のみAvailabilityZoneの数だけ生成
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(
    aws_vpc.main.cidr_block,
    2 * length(local.availability_zones), # (public, private) x availability_zone数
    count.index
  )
  availability_zone       = local.availability_zones[count.index].name
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform-public-${local.availability_zones[count.index].zone_id}"
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
  count          = length(aws_subnet.public)
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
    Name = "terraform-private-${local.availability_zones[count.index].zone_id}"
  }
}

# PrivateRoutingTable定義
resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.main.id

  # NATGatewayと紐づけ
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.environment == "pro" ? aws_nat_gateway.main[count.index].id : aws_nat_gateway.main[0].id
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

################################################################################
# Route53
################################################################################
# Route53ゾーン定義
resource "aws_route53_zone" "main" {
  name = "api.nakashimn.click"
}

# Route53レコード登録
resource "aws_route53_record" "main" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

################################################################################
# ACM
################################################################################
# サーバー証明書発行
resource "aws_acm_certificate" "main" {
  domain_name               = aws_route53_zone.main.name
  subject_alternative_names = ["*.${aws_route53_zone.main.name}"]
  validation_method         = "DNS"
}

# サーバー証明書の認証
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.main : record.fqdn]
}

# APIGatewayのエイリアス登録
resource "aws_route53_record" "api_gateway_alias" {
  name    = aws_api_gateway_domain_name.main.domain_name
  type    = "A"
  zone_id = aws_route53_zone.main.id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.main.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.main.regional_zone_id
  }
}
