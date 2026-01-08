provider "aws" {
  region = var.region
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_ip_cidr = "${trimspace(data.http.my_ip.response_body)}/32"

  azs = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c"
  ]

  private_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2),
    cidrsubnet(var.vpc_cidr, 8, 3),
    cidrsubnet(var.vpc_cidr, 8, 4),
    cidrsubnet(var.vpc_cidr, 8, 5)
  ]

  public_subnet = cidrsubnet(var.vpc_cidr, 8, 10)
}

module "keypair" {
  source = "../../modules/keypair"

  key_name   = var.key_name
  public_key = file(var.public_key_path)
}


module "network" {
  source          = "../../modules/network"
  vpc_cidr        = var.vpc_cidr
  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnet   = local.public_subnet

  openvpn_eni_id  = module.openvpn.eni_id
}

module "security" {
  source      = "../../modules/security"
  vpc_id      = module.network.vpc_id
  vpc_cidr    = var.vpc_cidr
  my_ip_cidr  = local.my_ip_cidr
}

module "k0s" {
  source = "../../modules/compute/k0s"

  ami                = var.ami
  instance_type      = var.k0s_instance_type
  key_name           = module.keypair.key_name
  private_subnet_ids = module.network.private_subnet_ids
  k0s_sg_id          = module.security.k0s_sg_id
}


module "observability" {
  source = "../../modules/compute/observability"

  ami                 = var.ami
  instance_type       = var.observability_instance_type
  key_name            = module.keypair.key_name
  private_subnet_ids  = slice(module.network.private_subnet_ids, 3, 5)
  observability_sg_id = module.security.observability_sg_id
}


module "openvpn" {
  source = "../../modules/compute/openvpn"

  ami              = var.ami
  instance_type    = var.openvpn_instance_type
  key_name         = module.keypair.key_name
  public_subnet_id = module.network.public_subnet_id
  openvpn_sg_id    = module.security.openvpn_sg_id
}

