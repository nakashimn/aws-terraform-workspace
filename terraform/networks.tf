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

# PublicRoutingTable定義
resource "aws_route_table" "public" {
  depends_on = [aws_vpc.main]

  count = length(aws_subnet.public)
  vpc_id = aws_vpc.main.id
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
  depends_on = [aws_route_table.public]

  count          = length(local.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
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

  count = length(local.availability_zones) # AvailabilityZoneの数だけ生成
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
# NATGateway
################################################################################
#NATGateway定義
resource "aws_nat_gateway" "main" {
  depends_on = [aws_subnet.public]

  count = length(aws_subnet.public)
  allocation_id = aws_eip.nat_gateway[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-gateway-terraform-${count.index}"
  }
}

# NATGateway用ElasticIP定義
resource "aws_eip" "nat_gateway" {
  depends_on = [aws_subnet.public]

  count = length(aws_subnet.public)

  tags = {
    Name = "elastic-ip-${count.index}"
  }
}

# PrivateRoutingTable定義
resource "aws_route_table" "private" {
  depends_on = [aws_vpc.main]

  count = length(aws_subnet.private)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "route-table-private-${count.index}"
  }
}

# PrivateRoutingTableとPrivateSubnetの紐づけ
resource "aws_route" "private" {
  depends_on = [
    aws_route_table.private,
    aws_nat_gateway.main
  ]

  count                  = length(aws_route_table.private)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# PrivateRoutingTableとPrivateSubnetの紐づけ
resource "aws_route_table_association" "private" {
  depends_on = [
    aws_subnet.private,
    aws_route_table.private
  ]

  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

################################################################################
# APIGateway
################################################################################
# APIGateway定義
resource "aws_api_gateway_rest_api" "main" {
  name = "aws-api-gateway-terraform"
}

# APIGatewayのリソース定義
resource "aws_api_gateway_resource" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# HTTPリクエストメソッド定義
resource "aws_api_gateway_method" "openapi_sample" {
  count         = length(var.acceptable_method)
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = var.acceptable_method[count.index]
  authorization = "NONE"
   request_parameters = {
    "method.request.path.proxy" = true
  }
}

# APIGatewayとALBのDNSの紐づけ
resource "aws_api_gateway_integration" "openapi_sample" {
  count                   = length(aws_api_gateway_method.openapi_sample)
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.main.id
  http_method             = aws_api_gateway_method.openapi_sample[count.index].http_method
  integration_http_method = aws_api_gateway_method.openapi_sample[count.index].http_method
  type                    = "HTTP_PROXY"
  uri                     = "http://${module.openapi_sample.aws_lb.dns_name}/{proxy}"
  cache_key_parameters = ["method.request.path.proxy"]
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.openapi_sample.id
}

# APIGatewayとアクセス制御用Policyの紐づけ
resource "aws_api_gateway_rest_api_policy" "internal" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  policy      = data.aws_iam_policy_document.api_gateway.json
}

# APIGatewayとVPCLinkの紐づけ
resource "aws_api_gateway_vpc_link" "openapi_sample" {
  name        = "api-gateway-vpc-link-openapi-sample"
  target_arns = [module.openapi_sample.aws_lb.arn]
}

# APIGatewayデプロイ定義
resource "aws_api_gateway_deployment" "openapi_sample" {
  depends_on    = [aws_api_gateway_integration.openapi_sample]

  rest_api_id   = aws_api_gateway_rest_api.main.id
  triggers      = {
    redeployment = sha1(
      jsonencode(
        [
          aws_api_gateway_resource.main.id,
          aws_api_gateway_method.openapi_sample.*.id,
          aws_api_gateway_integration.openapi_sample.*.id,
        ]
      )
    )
  }
}

# APIデプロイ先Stage定義
resource "aws_api_gateway_stage" "openapi_sample" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.openapi_sample.id
  stage_name = "develop"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format          = replace(file("${path.module}/assets/logformat/api_gateway.json"), "\n", "")
  }
}

# Logging用Role紐づけ
resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway.arn
}

# APIGateway用Logger定義
resource "aws_cloudwatch_log_group" "api_gateway" {
  name = "/api-gateway/"
}
