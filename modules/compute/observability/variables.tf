variable "ami" {}
variable "instance_type" {}

variable "key_name" {
  description = "SSH key name (from keypair module)"
}

variable "private_subnet_ids" {}
variable "observability_sg_id" {}

variable "instance_count" {
  default = 2
}
