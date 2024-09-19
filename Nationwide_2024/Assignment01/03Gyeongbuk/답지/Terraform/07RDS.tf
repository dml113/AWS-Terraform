resource "aws_db_subnet_group" "wsi_aurora_mysql_subnet_groups" {
  name       = "wsi-aurora-mysql-subnet-groups"
  subnet_ids = [
    aws_subnet.data-subnet-a.id,
    aws_subnet.data-subnet-b.id,
  ]

  tags = {
    Name = "wsi-aurora-mysql-subnet-groups"
  }
}

resource "aws_rds_cluster" "wsi_aurora_mysql_cluster" {
  cluster_identifier      = "wsi-aurora-mysql"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.05.2"
  master_username         = "admin"
  master_password         = "Skill53##"
  database_name           = "wsidata"
  db_subnet_group_name    = aws_db_subnet_group.wsi_aurora_mysql_subnet_groups.name
  vpc_security_group_ids  = [aws_security_group.all-security-groups.id]
  skip_final_snapshot     = true
  enabled_cloudwatch_logs_exports = ["audit", "error"]
  availability_zones      = ["${var.region}a", "${var.region}b"] # Fixed AZs
  apply_immediately       = true
  engine_mode             = "provisioned"
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds_kms.arn
  port                    = 3307 

  tags = {
    Name = "wsi-aurora-mysql-cluster"
  }
}

resource "aws_rds_cluster_instance" "wsi_aurora_mysql_instance" {
  count                   = 2
  identifier              = "wsi-aurora-mysql-instance${count.index + 1}"
  cluster_identifier      = aws_rds_cluster.wsi_aurora_mysql_cluster.id
  instance_class          = "db.t3.medium"
  engine                  = aws_rds_cluster.wsi_aurora_mysql_cluster.engine
  engine_version          = aws_rds_cluster.wsi_aurora_mysql_cluster.engine_version
  db_subnet_group_name    = aws_db_subnet_group.wsi_aurora_mysql_subnet_groups.name
  tags = {
    Name = "wsi-aurora-mysql-instance-${count.index + 1}"
  }
}
