variable "ami" {}
variable "instance_type" {}

variable "key_name" {
  description = "SSH key name (provided by keypair module)"
}

variable "private_subnet_ids" {}
variable "k0s_sg_id" {}

variable "worker_count" {
  default = 2
}
