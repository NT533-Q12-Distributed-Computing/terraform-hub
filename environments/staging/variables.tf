# =========================
# AWS & Global
# =========================
variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

# =========================
# SSH
# =========================
variable "key_name" {
  type = string
}

variable "public_key_path" {
  type = string
}

# =========================
# AMI
# =========================
variable "ami" {
  type = string
}

# =========================
# Compute - STAGING
# =========================

# k0s cluster
variable "k0s_instance_type" {
  type        = string
  description = "Instance type for k0s controller & workers"
}

# Observability nodes
variable "observability_instance_type" {
  type        = string
  description = "Instance type for Grafana / Prometheus / Loki / Tempo nodes"
}

# OpenVPN
variable "openvpn_instance_type" {
  type        = string
  description = "Instance type for OpenVPN server"
}
