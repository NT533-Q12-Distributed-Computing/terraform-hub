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
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet
  availability_zone       = var.azs[2]
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
  subnet_id     = aws_subnet.public.id

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
  subnet_id      = aws_subnet.public.id
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

# Route: Private subnet -> OpenVPN (VPN return path)
# NOTE:
# This route provides the return path from private subnets to VPN clients.
# Traffic destined to the VPN CIDR is forwarded to the OpenVPN EC2 ENI.
#
# The OpenVPN ENI is created at runtime, therefore this route is considered
# a late-binding dependency. In practice, this route may be applied
# post-provisioning (e.g. via Ansible/AWS CLI) to avoid Terraform plan-time
# ambiguity.

resource "aws_route" "private_to_openvpn" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = var.vpn_cidr
  network_interface_id   = var.openvpn_eni_id
}
