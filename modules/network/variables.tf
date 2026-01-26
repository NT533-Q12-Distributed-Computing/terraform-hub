variable "vpc_cidr" {}

variable "azs" {}

variable "private_subnets" {}

variable "public_subnet" {}

# CIDR assigned to VPN clients by OpenVPN server
variable "vpn_cidr" {
  description = "VPN client CIDR (OpenVPN)"
  type        = string
  default     = "10.8.0.0/24"
}

variable "openvpn_eni_id" {
  description = "Primary network interface ID of OpenVPN EC2"
  type        = string
  default     = null
}

# Optional EKS cluster name.
# Used only in production for Kubernetes-related subnet tagging.
# Null in k0s ( staging environment).
variable "cluster_name" {
  type = string
  default = null
}
