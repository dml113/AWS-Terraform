#resource "random_string" "rds_secrets" {
#  length  = 4
#  special = false
#  upper   = false
#}

#resource "aws_secretsmanager_secret" "rds_secret" {
#  provider = aws.ap
#  name = "rds_secret_${random_string.rds_secrets.result}"
#  recovery_window_in_days = 0
#}
#
#resource "aws_secretsmanager_secret_version" "rds_secret_version" {
#  provider = aws.ap
#  secret_id     = aws_secretsmanager_secret.rds_secret.id
#  secret_string = jsonencode({
#    username = "admin"
#    password = "supersecretpassword"
#  })
#}

resource "aws_db_subnet_group" "rds_subnet_group" {
  provider = aws.ap
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.wsi_data_a.id, aws_subnet.wsi_data_b.id]

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_security_group" "rds_security_group" {
  provider = aws.ap
  name        = "rds_security_group"
  description = "RDS security group"
  vpc_id      = aws_vpc.wsi_vpc.id

  ingress {
    from_port   = 3310
    to_port     = 3310
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with more specific rules if needed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with more specific rules if needed
  }

  tags = {
    Name = "rds-security-group"
  }
}

# resource "aws_rds_cluster" "rds_cluster" {
#   cluster_identifier      = "wsi-rds-mysql"
#   engine                  = "mysql"
#   engine_version          = "8.0.35"
#   master_username         = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["username"]
#   master_password         = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["password"]
#   database_name           = "wsi"
#   db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
#   vpc_security_group_ids  = [aws_security_group.rds_security_group.id]
#   storage_encrypted       = true
#   apply_immediately       = true
#   skip_final_snapshot     = true
#   availability_zones      = ["ap-northeast-2a", "ap-northeast-2b"]

#   tags = {
#     Name = "wsi-rds-cluster"
#   }

#   lifecycle {
#     ignore_changes = [master_password]
#   }
  
# }

# resource "aws_db_instance" "rds_instances" {
#   for_each = toset(["ap-northeast-2a", "ap-northeast-2b"])
#   identifier         = "wsi-rds-mysql-${each.key}"
#   instance_class     = "db.m5.xlarge"
#   multi_az             = true
#   db_subnet_group_name        = aws_db_subnet_group.rds_subnet_group.name
#   engine             = "mysql"
#   allocated_storage   = 20
#   engine_version     = "8.0.35"
#   availability_zone  = each.key
#   publicly_accessible = false
#   username          = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["username"]
#   password          = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["password"]
#   backup_retention_period = 7
#   storage_encrypted = true

#   tags = {
#     Name = "wsi-rds-instance-${each.key}"
#   }
# }

resource "aws_db_instance" "default" {
  provider = aws.ap
  enabled_cloudwatch_logs_exports = [
    "audit",
    "error",
    "general",
    "slowquery"
  ]
  allocated_storage     = 20
  identifier         = "wsi-rds-mysql"
  engine           = "mysql"
  engine_version     = "8.0.35"
  instance_class     = "db.m5.xlarge"
  db_name                  = "mydb"  
  # username          = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["username"]
  # password          = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["password"]
  username = "admin"
  manage_master_user_password = true
  backup_retention_period = 5
  backup_window         = "07:00-09:00"
  skip_final_snapshot     = true
  multi_az              = true
  port = 3310
  vpc_security_group_ids  = [aws_security_group.rds_security_group.id]
  db_subnet_group_name        = aws_db_subnet_group.rds_subnet_group.name
  storage_encrypted       = true
  tags = {
    Name = "wsi-rds-instance"
  }
}



resource "aws_cloudwatch_log_group" "rds_log_group" {
  provider = aws.ap
  name              = "/aws/rds/cluster/wsi-rds-mysql"
  retention_in_days = 7
}

resource "aws_rds_cluster_parameter_group" "rds_cluster_parameter_group" {
  provider = aws.ap
  name   = "rds-cluster-parameter-group"
  family = "aurora-mysql8.0"

  parameter {
    name  = "general_log"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "log_output"
    value = "FILE"
  }
}

resource "aws_iam_role" "rds_secret_rotation_role" {
  name = "rds_secret_rotation_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_secret_rotation_role_policy_attachment" {
  role       = aws_iam_role.rds_secret_rotation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "rds_secret_rotation_secretsmanager_policy_attachment" {
  role       = aws_iam_role.rds_secret_rotation_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

output "db_address" {
  value = aws_db_instance.default.address
}
