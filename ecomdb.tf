## Creating Launch Configuration
resource "aws_launch_configuration" "ecomdb-lc" {
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
resource "aws_autoscaling_group" "ecomdb-asg" {
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
