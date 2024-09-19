resource "aws_vpc_endpoint" "dynamodb_interface" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.app-subnet-a.id,aws_subnet.app-subnet-b.id]
  security_group_ids = [aws_security_group.all-security-groups.id]

  tags = {
    Name = "wsi-end-dynamodb"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr_interface" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.app-subnet-a.id,aws_subnet.app-subnet-b.id]
  security_group_ids = [aws_security_group.all-security-groups.id]

  tags = {
    Name = "wsi-end-ecr.dkr"
  }
}

resource "aws_vpc_endpoint" "ecr_api_interface" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.app-subnet-a.id,aws_subnet.app-subnet-b.id]
  security_group_ids = [aws_security_group.all-security-groups.id]

  tags = {
    Name = "wsi-end-ecr.api"
  }
}