resource "aws_lb_target_group" "target-group" {
  name = "target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.rpl-vpc.id
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
  security_groups = [ aws_security_group.rpl-security-group.id ]
  subnets = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id, aws_subnet.subnet-3.id]
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

output "loadbalancer-dns" {
  value = aws_lb.load-balancer.dns_name
}