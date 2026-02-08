# ==================================================
# Network Module
# ==================================================
# This module provisions the base VPC networking:
# - VPC, subnets (public/private)
# - Internet Gateway and NAT Gateway
# - Route tables for internet and VPN connectivity
#
# Static network resources are provisioned via Terraform.
# Runtime-dependent VPN routing is intentionally separated
# to avoid Terraform late-binding dependency issues.
# ==================================================


# =================
# Virtual Private Cloud
# =================
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "k0s-vpc"
  }
}

# =================
# Internet Gateway
# =================

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# =================
# Private Subnets
# =================
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index % length(var.azs)]

  tags = merge(
    {
      Name = "k0s-private-${count.index + 1}"

      # Required for internal LB
      "kubernetes.io/role/internal-elb" = "1"
    },
    var.cluster_name != null ? {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    } : {}
  )
}

# =================
# Public Subnets
# =================
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "k0s-public-ingress"

      # Required for public LB
      "kubernetes.io/role/elb" = "1"
    },
    var.cluster_name != null ? {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    } : {}
  )
}

# ==================================
# Elastic IP - Fixed IP for NAT
# ==================================
resource "aws_eip" "nat" {
  domain = "vpc"
}

# ==================================
# NAT Gateway
# ==================================
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.this]
}

# ==================================================
# Public Route Table - 0.0.0.0 to Internet Gateway
# ==================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# ==================================================
# Private Route Table
# ==================================================
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
}

# Default outbound route for private subnets (Internet access via NAT)
resource "aws_route" "private_to_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

#
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

