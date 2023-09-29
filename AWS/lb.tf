resource "aws_lb_target_group" "target-group" {
  name = "target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = "vpc-058547a43fcee67cf"
  health_check {
    enabled = true
    healthy_threshold = 3
    interval = 10
    matcher = 200
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
    timeout = 3
    unhealthy_threshold = 2
  }
}

# resource "aws_lb_target_group_attachment" "attach-target-group" {
#   target_group_arn = aws_lb_target_group.target-group.arn
#   port = 1234
# }

resource "aws_lb" "load-balancer" {
  name = "load-balancer"
  internal = false
  load_balancer_type = "application"
  security_groups = [ "sg-0b25b7859155bcde5" ]
  subnets = ["subnet-09c24fde4eb965cb4", "subnet-06a261c9dbd53f4a3", "subnet-0715e175e8ca284d0"]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load-balancer.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}