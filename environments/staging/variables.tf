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

variable "ssh_key_path" {
  type        = string
  description = "Path to SSH private key for Ansible"
}

# =========================
# Ansible
# =========================
variable "ansible_inventory_dir" {
  type        = string
  description = "Base directory for Ansible inventories"
}

# =========================
# VPC and AZ
# =========================
variable "az_count" {
  type = number

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3"
  }
}


variable "subnet_newbits" {
  type        = number
  description = "Subnet newbits for CIDR calculation"
}

variable "private_subnet_indexes" {
  type        = list(number)
}

variable "public_subnet_indexes" {
  type        = list(number)
}

variable "observability_subnet_slice" {
  type = list(number)

  validation {
    condition     = length(var.observability_subnet_slice) == 2
    error_message = "observability_subnet_slice must have exactly 2 elements: [start, end]"
  }
}

variable "openvpn_public_subnet_index" {
  type = number
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

# =========================
# Application Load Balancer
# =========================
variable "alb_target_port" {
  type        = number
  description = "Target port for ALB (NodePort / Ingress)"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

