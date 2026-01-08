resource "aws_instance" "controller" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[0]
  key_name               = var.key_name
  vpc_security_group_ids = [var.k0s_sg_id]

  tags = {
    Name = "k0s-controller"
  }
}

resource "aws_instance" "workers" {
  count                  = var.worker_count
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index + 1]
  key_name               = var.key_name
  vpc_security_group_ids = [var.k0s_sg_id]

  tags = {
    Name = "k0s-worker-${count.index + 1}"
  }
}
