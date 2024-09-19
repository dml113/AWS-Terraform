resource "aws_lb" "gm-alb" {
  name               = "gm-alb"
  internal           = true
  load_balancer_type = "application"
  
  subnets = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]

  security_groups = [aws_security_group.alb-sg.id]

  tags = {
    Name        = "gm-alb"
  }
}

resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb-sg"
  }
}

resource "aws_lb_target_group" "gm-tg" {
  name        = "gm-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_vpc.id

  health_check {
    path                = "/healthcheck"
    protocol            = "HTTP"
    port                = 5000
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "gm-tg"
  }
}

resource "aws_lb_target_group_attachment" "example" {
  target_group_arn = aws_lb_target_group.gm-tg.arn
  target_id        = aws_instance.webapp_instance.id
  port             = 5000
}

resource "aws_lb_listener" "gm-alb_listener" {
  load_balancer_arn = aws_lb.gm-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gm-tg.arn
  }
}