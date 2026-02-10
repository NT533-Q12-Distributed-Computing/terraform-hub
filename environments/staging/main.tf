# =========================
# PROVIDER
# =========================
provider "aws" {
  region = var.region
}

# =========================
# DATA SOURCES
# =========================

# Get current public IP (used for SSH / VPN access)
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# Fetch available Availability Zones (avoid hardcoding a/b/c)
data "aws_availability_zones" "available" {
  state = "available"
}

# Fetch latest Ubuntu 22.04 LTS AMI from Canonical
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# =========================
# LOCALS
# =========================
locals {
  # Admin public IP in CIDR format
  my_ip_cidr = "${trimspace(data.http.my_ip.response_body)}/32"

  # Use first 3 AZs for staging environment
  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    var.az_count
  )

  # Private subnets (Kubernetes nodes, observability, internal services)
  private_subnets = [
    for i in var.private_subnet_indexes :
    cidrsubnet(var.vpc_cidr, var.subnet_newbits, i)
  ]

  public_subnets = [
    for i in var.public_subnet_indexes :
    cidrsubnet(var.vpc_cidr, var.subnet_newbits, i)
  ]
}


# =========================
# SSH KEY PAIR
# =========================
# Shared SSH key for all EC2 instances
module "keypair" {
  source = "../../modules/keypair"

  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# =========================
# NETWORK
# VPC, SUBNETS, ROUTING
# =========================
module "network" {
  source          = "../../modules/network"
  vpc_cidr        = var.vpc_cidr
  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
}

# =========================
# SECURITY
# SECURITY GROUPS
# =========================
module "security" {
  source     = "../../modules/security"
  vpc_id     = module.network.vpc_id
  vpc_cidr   = var.vpc_cidr
  my_ip_cidr = local.my_ip_cidr
}

# =========================
# K0S KUBERNETES CLUSTER
# CONTROL PLANE + WORKERS
# =========================
module "k0s" {
  source = "../../modules/compute/k0s"

  ami                = data.aws_ami.ubuntu_2204.id
  instance_type      = var.k0s_instance_type
  key_name           = module.keypair.key_name
  private_subnet_ids = module.network.private_subnet_ids
  k0s_sg_id          = module.security.k0s_sg_id
}

# =========================
# OBSERVABILITY NODES
# PROMETHEUS / LOKI / TEMPO / GRAFANA
# =========================
module "observability" {
  source = "../../modules/compute/observability"

  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.observability_instance_type
  key_name      = module.keypair.key_name

  # Dedicated subnets for observability stack
  private_subnet_ids = slice(
    module.network.private_subnet_ids,
    var.observability_subnet_slice[0],
    var.observability_subnet_slice[1]
  )

  observability_sg_id = module.security.observability_sg_id
}

# =========================
# OPENVPN GATEWAY
# BASTION / ADMIN ACCESS
# =========================
module "openvpn" {
  source = "../../modules/compute/openvpn"

  ami              = data.aws_ami.ubuntu_2204.id
  instance_type    = var.openvpn_instance_type
  key_name         = module.keypair.key_name
  public_subnet_id = module.network.public_subnet_ids[var.openvpn_public_subnet_index]
  openvpn_sg_id    = module.security.openvpn_sg_id
}

# =========================
# APPLICATION LOAD BALANCER
# =========================
module "alb" {
  source = "../../modules/alb"

  name = "${var.environment}-k0s-alb"
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.public_subnet_ids
  alb_sg_id  = module.security.alb_sg_id

  target_type  = "instance"
  target_port = var.alb_target_port
  instance_ids = module.k0s.instance_ids
}
