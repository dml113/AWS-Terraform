module "vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = "app-vpc"
    cidr = "10.0.0.0/16"

    azs = ["us-east-2a", "us-east-2b"]

    public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
    public_subnet_names = ["app-public-a", "app-public-b"]
    map_public_ip_on_launch = true

    enable_dns_hostnames = true
    enable_dns_support   = true
}


module "app_server_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "app-server"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "0.0.0.0/0"
    }
  ]  
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"

  name = "app-server"

  min_size                  = 1
  max_size                  = 10
  desired_capacity          = 1
  vpc_zone_identifier       = module.vpc.public_subnets

  # Launch template
  launch_template_name        = "app-asg-lt"
  launch_template_description = "app-asg-lt"
  update_default_version      = true

  image_id          = "ami-0604f27d956d83a4d"
  instance_type     = "t3.micro"

  create_iam_instance_profile = true
  iam_role_name               = "app-asg-role"

  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AWSCodeDeployRole            = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
    AdministratorAccess          = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [ module.app_server_sg.security_group_id ]
    }
  ]

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = { Name = "app-server" }
    }
  ]
  user_data = filebase64("user_data.sh")
}


module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "app-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}

resource "aws_lb_target_group" "target_group" {
  name     = "app-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    interval            = 30
    path                = "/health"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "wsi_listener" {
  load_balancer_arn = module.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = module.asg.autoscaling_group_id
  lb_target_group_arn   = aws_lb_target_group.target_group.arn
}