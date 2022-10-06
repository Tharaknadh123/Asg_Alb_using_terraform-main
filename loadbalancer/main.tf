# LoadBalancing main.tf
resource "aws_lb" "ekart_alb" {
  name = "ekart-alb"
  subnets = var.subnet_ids  #from network outputs
  security_groups = [var.public_sg_id] #public http sg which allows traffic from anywhere
  idle_timeout = 400
}

resource "aws_lb_target_group" "home_tg" {
  name     = "home-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "products_tg" {
  name     = "products-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/products/"
  }
  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = "${aws_lb.ekart_alb.arn}"
  port = 80
  protocol = "HTTP"
  default_action {
    target_group_arn = "${aws_lb_target_group.home_tg.arn}"
    type = "forward"
  }
}

resource "aws_lb_listener_rule" "lr" {
  listener_arn = aws_lb_listener.lb_listener.arn
  priority = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.products_tg.arn
  }
  condition {
    path_pattern {
      values = ["*/products*"]
    }
  }
}
