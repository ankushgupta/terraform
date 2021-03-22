provider "aws" {
  access_key = "XXXXXXX"
  secret_key = "XXXXX"
  region     = "us-east-2"
}
data "aws_availability_zones" "all" {}

data "aws_subnet_ids" "this" {
  vpc_id =  "vpc-c2ac2fa9"

  tags = {
    Tier = "Public subnet"
  }
}

resource "aws_lb" "nlb" {
  load_balancer_type         = "network"
  name_prefix                = "demo"
  internal                   = var.internal
  subnets                    = data.aws_subnet_ids.this.ids

  enable_cross_zone_load_balancing = true


}

resource "aws_lb_target_group" "this" {

  port        = 80
  protocol    = "TCP"
  vpc_id      = "vpc-c2ac2fa9"


  depends_on = [
    aws_lb.nlb
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "this" {

  load_balancer_arn = aws_lb.nlb.arn

  protocol          = "TCP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_autoscaling_attachment" "target" {

  autoscaling_group_name = "${aws_autoscaling_group.example.id}"
  alb_target_group_arn   = aws_lb_target_group.this.arn
}

## Creating Launch Configuration
resource "aws_launch_configuration" "example" {
  image_id               = "ami-09246ddb00c7c4fef"
  instance_type          = "t2.micro"
  security_groups        = ["sg-0644baaa131aae3e7"]
  key_name               = "terraform.pem"
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

## Creating AutoScaling Group
resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = data.aws_availability_zones.all.names
  min_size = 2
  max_size = 10
  load_balancers = ["${aws_lb.nlb.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}
