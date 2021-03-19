data "aws_subnet_ids" "this" {
  vpc_id = var.vpc_id

  tags = {
    Tier = "Public"
  }
}

resource "aws_lb" "this" {
  name               = "basic-load-balancer"
  load_balancer_type = "network"
  subnets            = data.aws_subnet_ids.this.ids

  enable_cross_zone_load_balancing = true
}

variable "ports" {
  type    = map(number)
  default = {
    http  = 80
    https = 443
  }
}

resource "aws_lb_listener" "this" {
  for_each = var.ports

  load_balancer_arn = aws_lb.this.arn

  protocol          = "TCP"
  port              = each.value

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }
}

resource "aws_lb_target_group" "this" {
  for_each = var.ports

  port        = each.value
  protocol    = "TCP"
  vpc_id      = var.vpc_id

  stickiness = []

  depends_on = [
    aws_lb.this
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "target" {
  for_each = var.ports

  autoscaling_group_name = var.autoscaling_group_name
  alb_target_group_arn   = aws_lb_target_group.this[each.value].arn
}

resource "aws_lb_target_group" "this" {
  for_each = var.ports

  port        = each.value
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  depends_on = [
    aws_lb.this
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = local.ports_ips_product

  target_group_arn  = aws_lb_target_group.this[each.value.port].arn
  target_id         = each.value.ip
  availability_zone = "all"
  port              = each.value
}

locals {
  ports_ips_product = flatten(
    [
      for port in values(var.ports): [
        for eni in keys(data.aws_network_interface.this): {
          port = port
          ip   = data.aws_network_interface.this[eni].private_ip
        }
      ]
    ]
  )
}

data "aws_network_interfaces" "this" {
  filter {
    name   = "description"
    values = ["ENI for target"]
  }
}

data "aws_network_interface" "this" {
  for_each = toset(data.aws_network_interfaces.this.ids)
  id       = each.key
}

resource "aws_security_group" "this" {
  description = "Allow connection between NLB and target"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ingress" {
  for_each = var.ports

  security_group_id = aws_security_group.this.id
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}


