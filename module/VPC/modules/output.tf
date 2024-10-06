output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_a_id" {
  value = aws_subnet.public[0].id
}

output "public_subnet_b_id" {
  value = aws_subnet.public[1].id
}

output "private_subnet_a_id" {
  value = aws_subnet.private[0].id
}

output "private_subnet_b_id" {
  value = aws_subnet.private[1].id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "data_subnet_ids" {
  value = [for subnet in aws_subnet.data : subnet.id]
}