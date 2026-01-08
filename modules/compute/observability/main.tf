resource "aws_instance" "this" {
  count                  = var.instance_count
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index]
  key_name               = var.key_name
  vpc_security_group_ids = [var.observability_sg_id]

  tags = {
    Name = "observability-${count.index + 1}"
  }
}
