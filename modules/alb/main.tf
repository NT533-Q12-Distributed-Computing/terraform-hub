# =========================
# Application Load Balancer
# =========================
resource "aws_lb" "this" {
  name               = var.name
  load_balancer_type = "application"
  internal           = false

  subnets         = var.subnet_ids
  security_groups = [var.alb_sg_id]
}

# =========================
# Target Group (ALB L7)
# =========================
resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg"
  port        = var.target_port
  protocol    = var.target_protocol
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    path = var.health_check_path
  }
}

# =========================
# Listener (HTTP)
# =========================

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# ==================================================
# Attach targets – k0s (instance / NodePort)
# ==================================================
resource "aws_lb_target_group_attachment" "instance" {
  count = var.target_type == "instance" ? length(var.instance_ids) : 0

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.instance_ids[count.index]
  port             = var.target_port
}


# ==================================================
# Attach targets – EKS (ip / Pod IP)
# ==================================================
resource "aws_lb_target_group_attachment" "ip" {
  for_each = var.target_type == "ip" ? toset(var.target_ips) : toset([])

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = each.value
  port             = var.target_port
}

