# --- ECS Cluster ---
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "wsi-ecs"
}

# --- ECS Node Role ---
data "aws_iam_policy_document" "ecs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_node_role" {
  name_prefix        = "demo-ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = "demo-ecs-node-profile"
  path        = "/ecs/instance/"
  role        = aws_iam_role.ecs_node_role.name
}

# --- ECS Launch Template ---
data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "ecs_ec2" {
  name_prefix            = "wsi-ecs-"
  image_id               = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.ecs-wsi-alb.id]

  iam_instance_profile { arn = aws_iam_instance_profile.ecs_node.arn }
  monitoring { enabled = true }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config;
    EOF
  )
}

# --- ECS ASG ---
resource "aws_autoscaling_group" "ecs" {
  name_prefix               = "wsi-ecs-asg-"
  vpc_zone_identifier       = [aws_subnet.app-subnet-a.id]
  min_size                  = 2
  max_size                  = 8
  health_check_grace_period = 0
  health_check_type         = "EC2"
  protect_from_scale_in     = false

  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "wsi-ecs"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

# --- ECS Task Role ---
data "aws_iam_policy_document" "ecs_task_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name        = "demo-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role" "ecs_exec_role" {
  name        = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "app" {
  family             = "wsi-task"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 256

  container_definitions = jsonencode([{
    name         = "app"
    image        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/wsi-ecr:latest"
    essential    = true
    portMappings = [{ containerPort = 80, hostPort = 80 }]

    environment = [
      { name = "EXAMPLE", value = "example" }
    ]
  }])
}

# --- ECS Service ---
resource "aws_ecs_service" "app" {
  name            = "wsi-ecs-s"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    security_groups = [aws_security_group.ecs-wsi-alb.id]
    subnets         = [aws_subnet.app-subnet-a.id, aws_subnet.app-subnet-b.id]
  }

  depends_on = [
    aws_lb_target_group.app,
    aws_lb_target_group.green
  ]

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 80
  }
}

# --- ALB ---
resource "aws_lb" "main" {
  name               = "wsi-alb-ci"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]
  security_groups    = [aws_security_group.ecs-wsi-alb.id]
}

resource "aws_lb_target_group" "app" {
  name        = "wsi-target-group-app"
  vpc_id      = aws_vpc.vpc.id
  protocol    = "HTTP"
  port        = 80
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "green" {
  name        = "wsi-target-group-green"
  vpc_id      = aws_vpc.vpc.id
  protocol    = "HTTP"
  port        = 80
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.main.id
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }
}
