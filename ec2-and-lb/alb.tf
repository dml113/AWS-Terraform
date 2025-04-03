module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "alb-sg"
  description = "Security group for web-server with HTTP ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "0.0.0.0/0"
    }
  ]      
}

resource "aws_lb_target_group" "iac_nginx_alb" {
  name     = "iac-nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  target_type = "instance"
}

resource "aws_lb" "test" {
  name               = "iac-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.web_server_sg.security_group_id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.iac_nginx_alb.arn
  }
}

resource "aws_lb_target_group_attachment" "lb_target_group_attach-a" {
  target_group_arn = aws_lb_target_group.iac_nginx_alb.arn
  target_id        = aws_instance.app-server-a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "lb_target_group_attach-c" {
  target_group_arn = aws_lb_target_group.iac_nginx_alb.arn
  target_id        = aws_instance.app-server-c.id
  port             = 80
}