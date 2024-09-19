resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_default_subnet.default_vpc_subnet_a.id, aws_default_subnet.default_vpc_subnet_b.id]
  security_groups    = [aws_security_group.allow_all.id]

  enable_deletion_protection = false

  tags = {
    Name = "example-alb"
  }
}

resource "aws_lb_target_group" "example_tg" {
  name        = "example-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_default_vpc.default_vpc.id
  target_type = "ip"

  health_check {
    path                = "/healthcheck"
    interval            = 5
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "example-tg"
  }
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_tg.arn
  }
}

resource "aws_ecs_cluster" "example" {
  name = "example-cluster"
}

resource "aws_ecs_task_definition" "example" {
  family                   = "example-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = <<DEFINITION
[
  {
    "name": "example",
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-west-1.amazonaws.com/wsc2024-repo:latest",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ]
  }
]
DEFINITION

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn

  tags = {
    Name = "example-task"
  }
}

resource "aws_ecs_service" "example" {
  name            = "example-service"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_default_subnet.default_vpc_subnet_a.id, aws_default_subnet.default_vpc_subnet_b.id]
    security_groups  = [aws_security_group.allow_all.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.example_tg.arn
    container_name   = "example"
    container_port   = 8080
  }

  desired_count = 1

  tags = {
    Name = "example-service"
  }

  depends_on = [
    aws_lb_listener.example
  ]
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = "ecsTaskExecutionRole"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS 서비스에 필요한 API 작업을 포함하는 IAM 정책 생성
data "aws_iam_policy_document" "ecs_policy_document" {
  statement {
    actions = [
      "ecs:CreateCluster",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:DeleteService",
      "ecs:CreateService",
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListClusters",
      "ecs:ListServices",
      "ecs:ListTaskDefinitionFamilies",
      "ecs:ListTaskDefinitions",
      "ecs:ListTasks",
      "ecs:UpdateServicePrimaryTaskSet",
      "ecs:RunTask",
      "ecs:StartTask",
      "ecs:StopTask",
      "ecs:UpdateServiceSetting",
      "ecs:DescribeContainerInstances",
      "ecs:ListContainerInstances",
    ]
    resources = ["*"]
  }
}

# ECS IAM 정책 생성
resource "aws_iam_policy" "ecs_policy" {
  name        = "ecs-policy"
  description = "Policy for ECS"
  policy      = data.aws_iam_policy_document.ecs_policy_document.json
}

# ECS IAM 정책을 ECS 역할에 연결
resource "aws_iam_role_policy_attachment" "ecs_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_policy.arn
}
