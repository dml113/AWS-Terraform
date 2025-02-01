output "vpc_id" {
  value = aws_vpc.this.id
}

output "igw_id" {
  value = aws_internet_gateway.this[0].id
}

output "nat_gateway_ids" {
  value = { for key, nat in aws_nat_gateway.this : key => nat.id }
}

output "subnet_ids" {
  description = "Subnet IDs for all subnets"
  value = {
    for subnet_key, subnet in aws_subnet.this :
    subnet_key => subnet.id
  }
}