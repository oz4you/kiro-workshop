# -----------------------------------------------------------------------------
# Security Group for VPC Endpoints
# -----------------------------------------------------------------------------

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project}-${var.env}-vpce-sg"
  description = "Security group for VPC endpoints (HTTPS from VPC CIDR only)"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.env}-vpce-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_https" {
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow HTTPS from VPC CIDR"
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# -----------------------------------------------------------------------------
# Interface VPC Endpoints
# -----------------------------------------------------------------------------

locals {
  interface_endpoints = {
    ecr_api = "com.amazonaws.${var.aws_region}.ecr.api"
    ecr_dkr = "com.amazonaws.${var.aws_region}.ecr.dkr"
    logs    = "com.amazonaws.${var.aws_region}.logs"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = aws_vpc.main.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    for subnet in aws_subnet.private_ecs_task : subnet.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  tags = {
    Name = "${var.project}-${var.env}-vpce-${each.key}"
  }
}

# -----------------------------------------------------------------------------
# Gateway VPC Endpoint (S3)
# -----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_ecs_task.id,
    aws_route_table.private_data.id,
  ]

  tags = {
    Name = "${var.project}-${var.env}-vpce-s3"
  }
}
