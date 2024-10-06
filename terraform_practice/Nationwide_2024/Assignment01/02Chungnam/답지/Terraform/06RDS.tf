# Create Security Group
resource "aws_security_group" "wsc2024_db_sg" {
  name_prefix = "wsc2024-db-sg-"
  vpc_id      = aws_vpc.wsc2024-storage-vpc.id
  
  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name = "wsc2024-db-sg"
  }
}
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "wsc2024-db-sgp"
  subnet_ids = [aws_subnet.wsc2024-storage-db-sn-a.id, aws_subnet.wsc2024-storage-db-sn-b.id]
  tags = {
    Name = "wsc2024-db-sgp"
  }
}
resource "aws_iam_role" "enhanced_monitoring_role" {
  name = "rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "enhanced_monitoring_policy_attachment" {
  role       = aws_iam_role.enhanced_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
# Create Aurora Cluster
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "wsc2024-db-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.05.2"
  master_username         = "admin"
  master_password         = "Skill53##"
  database_name           = "wsc2024_db"
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.wsc2024_db_sg.id]
  skip_final_snapshot     = true
  # Enable Backtracking
  backtrack_window        = 14400 # 4 hours in seconds
  # Enable Log Exports
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  # Enable Multi-AZ Deployment
  availability_zones = ["us-east-1a", "us-east-1b"] # Fixed AZs
  # Enable Enhanced Availability
  apply_immediately = true
  engine_mode       = "provisioned"
  tags = {
    Name = "aurora-cluster"
  }
}
# Create Writer Aurora Cluster Instance
resource "aws_rds_cluster_instance" "aurora_writer" {
  identifier              = "aurora-writer-instance"
  cluster_identifier      = aws_rds_cluster.aurora_cluster.id
  instance_class          = "db.t3.medium"
  engine                  = aws_rds_cluster.aurora_cluster.engine
  engine_version          = aws_rds_cluster.aurora_cluster.engine_version
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  publicly_accessible     = false
  availability_zone       = "us-east-1a"
  # Enable Enhanced Monitoring
  monitoring_interval     = 60 # Monitoring interval in seconds
  monitoring_role_arn     = aws_iam_role.enhanced_monitoring_role.arn
  tags = {
    Name = "aurora-writer-instance"
  }
}
# Create Reader Aurora Cluster Instances
resource "aws_rds_cluster_instance" "aurora_reader" {
  count                   = 1 # Number of reader instances (changed to 1)
  identifier              = "aurora-reader-instance-${count.index}"
  cluster_identifier      = aws_rds_cluster.aurora_cluster.id
  instance_class          = "db.t3.medium"
  engine                  = aws_rds_cluster.aurora_cluster.engine
  engine_version          = aws_rds_cluster.aurora_cluster.engine_version
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  publicly_accessible     = false
  availability_zone       = "us-east-1a" # Use the same availability zone as the writer instance
  # Enable Enhanced Monitoring
  monitoring_interval     = 60 # Monitoring interval in seconds
  monitoring_role_arn     = aws_iam_role.enhanced_monitoring_role.arn
  tags = {
    Name = "aurora-reader-instance-${count.index}"
  }
}