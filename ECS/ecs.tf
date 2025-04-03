module "ecs_service_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "ecs-service-sg"
  description = "Security group for web-server with HTTP ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

# define Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "iac-ecs-cluster"
}

# define Task
data "template_file" "template_container_definitions" {
  template = "${file("container-definitions.json.tpl")}"
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "iac-ecs-task"
  execution_role_arn       = "arn:aws:iam::950274644703:role/ecsTaskExecutionRole"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  container_definitions    = "${data.template_file.template_container_definitions.rendered}"
}

resource "aws_ecs_service" "ecs_service" {
  name            = "iac-nginx-svc"
  cluster         = "${aws_ecs_cluster.ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.ecs_task.arn}"
  desired_count   = "2"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [module.ecs_service_sg.security_group_id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.iac_nginx_alb.id}"
    container_name   = "nginx-container"
    container_port   = "80"
  }

  depends_on = ["aws_lb_listener.front_end"]
}