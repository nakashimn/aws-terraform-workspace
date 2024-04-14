################################################################################
# Params
################################################################################
locals {
  # AWSアベイラビリティゾーンの情報
  availability_zones = [
    for index, name in data.aws_availability_zones.available.names :
    {
      name    = name
      zone_id = data.aws_availability_zones.available.zone_ids[index]
    }
  ]
}

################################################################################
# VPC
################################################################################
# VPC定義
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
}

# InternetGateway定義
resource "aws_internet_gateway" "main" {
  depends_on = [aws_vpc.main]

  vpc_id = aws_vpc.main.id
}

# RoutingTable定義
resource "aws_route_table" "main" {
  depends_on = [aws_vpc.main]

  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# RoutingTableとPublicSubnetの紐づけ
resource "aws_route_table_association" "public" {
  depends_on = [aws_route_table.main]

  count          = length(local.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.main.id
}

################################################################################
# Subnets
################################################################################
# PublicSubnet定義
resource "aws_subnet" "public" {
  depends_on = [aws_vpc.main]

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

# PrivatesSubnet定義
resource "aws_subnet" "private" {
  depends_on = [aws_vpc.main]

  # count = length(local.availability_zones)
  count  = 0 # =disabled(リソースを生成しない)
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(
    aws_vpc.main.cidr_block,
    2 * length(local.availability_zones), # (public, private) x availability_zone数
    count.index + length(local.availability_zones)
  )
  availability_zone       = local.availability_zones[count.index].name
  map_public_ip_on_launch = false
  tags = {
    Name = "nakashimn-terraform-pribate-${local.availability_zones[count.index].zone_id}"
  }
}

################################################################################
# SecurityGroup
################################################################################
# SecurityGroup定義
resource "aws_security_group" "main" {
  depends_on = [aws_vpc.main]

  name   = "terraform-security-group"
  vpc_id = aws_vpc.main.id
}

# SecurityGroupRule(ssh接続用インバウンドルール)定義
resource "aws_security_group_rule" "ingress_ssh" {
  depends_on = [aws_security_group.main]

  security_group_id = aws_security_group.main.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ip_addresses
}

# SecurityGroupRule(外部向けインバウンドルール)定義
resource "aws_security_group_rule" "ingress" {
  depends_on = [aws_security_group.main]

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
  depends_on = [aws_security_group.main]

  security_group_id = aws_security_group.main.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

################################################################################
# APIGateway
################################################################################
# APIGateway定義
resource "aws_api_gateway_rest_api" "main" {
  name = "aws-api-gateway-terraform"
}

# APIGatewayのパス確保
resource "aws_api_gateway_resource" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = module.openapi_sample.name
}

# getメソッド定義
resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = "GET"
  authorization = "NONE"
}

# postメソッド定義
resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = "POST"
  authorization = "NONE"
}

# APIGatewayとALBのDNSの紐づけ(getメソッド)
resource "aws_api_gateway_integration" "openapi_sample_get" {
  depends_on = [module.openapi_sample.aws_lb]

  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.main.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${module.openapi_sample.aws_lb.dns_name}"

  # connection_type = "VPC_LINK"
  # connection_id   = "${aws_api_gateway_vpc_link.openapi_sample.id}"
}

# APIGatewayとALBのDNSの紐づけ(postメソッド)
resource "aws_api_gateway_integration" "openapi_sample_post" {
  depends_on = [module.openapi_sample.aws_lb]

  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.main.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "HTTP_PROXY"
  uri                     = "http://${module.openapi_sample.aws_lb.dns_name}"

  # connection_type = "VPC_LINK"
  # connection_id   = "${aws_api_gateway_vpc_link.openapi_sample.id}"
}

### ToBeDeveloped...
# resource "aws_api_gateway_deployment" "main" {
#   depends_on    = [aws_api_gateway_integration.openapi_sample_get]

#   rest_api_id   = aws_api_gateway_rest_api.main.id
#   stage_name    = "prod"
# }

# resource "aws_api_gateway_vpc_link" "openapi_sample" {
#   depends_on = [module.openapi_sample.aws_lb]

#   name        = "api-gateway-vpc-link-openapi-sample"
#   target_arns = [module.openapi_sample.aws_lb.arn]
# }
