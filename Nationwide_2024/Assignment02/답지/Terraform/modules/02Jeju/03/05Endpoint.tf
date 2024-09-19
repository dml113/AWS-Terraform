resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids   = [aws_route_table.private_a_route_table.id]

  tags = {
    Name = "J-company-endpoint-s3"
  }
}

#resource "aws_vpc_endpoint" "sqs_interface" {
#  vpc_id             = aws_vpc.vpc.id
#  service_name       = "com.amazonaws.ap-northeast-2.sqs"
#  vpc_endpoint_type  = "Interface"
#  subnet_ids         = [aws_subnet.private_subnet_a.id]
#  security_group_ids = [aws_security_group.J-company-sg-sqs.id]
#
#  tags = {
#    Name = "J-company-endpoint-sqs"
#  }
#}

resource "aws_ec2_instance_connect_endpoint" "ec2_instance_connect" {
  subnet_id           = aws_subnet.private_subnet_b.id
  security_group_ids  = [aws_security_group.J-company-bastion.id] 

  tags = {
    Name = "J-company-endpoint-ec2"
  }
}
