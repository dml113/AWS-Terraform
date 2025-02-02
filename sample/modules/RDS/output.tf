output "rds_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "rds_instance_id" {
  value = aws_db_instance.this.id
}

output "rds_subnet_group_name" {
  value = aws_db_subnet_group.rds_subnet_group.name
}

output "rds_parameter_group_name" {
  value = aws_db_parameter_group.rds_parameter_group.name
}
