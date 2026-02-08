variable "name" {
  type        = string
  description = "Application Load Balancer name"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Public subnets for ALB"
}

variable "alb_sg_id" {
  type = string
}

# Listener
variable "listener_port" {
  type    = number
  default = 80
}

variable "listener_protocol" {
  type    = string
  default = "HTTP"
}

# Target Group
variable "target_port" {
  type        = number
  description = "Port exposed by backend (NodePort or Service port)"
}

variable "target_protocol" {
  type    = string
  default = "HTTP"
}

variable "target_type" {
  type        = string
  description = "instance (k0s) or ip (EKS)"
  validation {
    condition     = contains(["instance", "ip"], var.target_type)
    error_message = "target_type must be instance or ip"
  }
}

variable "health_check_path" {
  type    = string
  default = "/"
}

# k0s only
variable "instance_ids" {
  type    = list(string)
  default = []
}

# EKS only
variable "target_ips" {
  type    = list(string)
  default = []
}
