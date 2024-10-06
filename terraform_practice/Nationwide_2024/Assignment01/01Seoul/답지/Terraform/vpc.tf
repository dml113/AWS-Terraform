resource "aws_vpc" "wsi_vpc" {
  provider = aws.ap
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "wsi-vpc"
  }
}

resource "aws_internet_gateway" "wsi_igw" {
  provider = aws.ap
  vpc_id = aws_vpc.wsi_vpc.id
  tags = {
    Name = "wsi-igw"
  }
}

resource "aws_subnet" "wsi_app_a" {
  provider = aws.ap
  availability_zone = "ap-northeast-2a"
  vpc_id            = aws_vpc.wsi_vpc.id
  cidr_block        = "10.1.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = "wsi-app-a"
  }
}

resource "aws_subnet" "wsi_app_b" {
  provider = aws.ap
  availability_zone = "ap-northeast-2b"
  vpc_id            = aws_vpc.wsi_vpc.id
  cidr_block        = "10.1.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = "wsi-app-b"
  }
}

resource "aws_subnet" "wsi_public_a" {
  provider = aws.ap
  availability_zone = "ap-northeast-2a"
  vpc_id            = aws_vpc.wsi_vpc.id
  cidr_block        = "10.1.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "wsi-public-a"
  }
}

resource "aws_subnet" "wsi_public_b" {
  provider = aws.ap
  availability_zone = "ap-northeast-2b"
  vpc_id            = aws_vpc.wsi_vpc.id
  cidr_block        = "10.1.3.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "wsi-public-b"
  }
}

resource "aws_subnet" "wsi_data_a" {
  provider = aws.ap
  availability_zone = "ap-northeast-2a"
  vpc_id            = aws_vpc.wsi_vpc.id
  cidr_block        = "10.1.4.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = "wsi-data-a"
  }
}

resource "aws_subnet" "wsi_data_b" {
  provider = aws.ap
  availability_zone = "ap-northeast-2b"
  vpc_id            = aws_vpc.wsi_vpc.id
  cidr_block        = "10.1.5.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = "wsi-data-b"
  }
}

resource "aws_nat_gateway" "wsi_natgw_a" {
  provider = aws.ap
  allocation_id = aws_eip.wsi_natgw_a.id
  subnet_id     = aws_subnet.wsi_public_a.id
  tags = {
    Name = "wsi-natgw-a"
  }
}

resource "aws_nat_gateway" "wsi_natgw_b" {
  provider = aws.ap
  allocation_id = aws_eip.wsi_natgw_b.id
  subnet_id     = aws_subnet.wsi_public_b.id
  tags = {
    Name = "wsi-natgw-b"
  }
}

resource "aws_eip" "wsi_natgw_a" {
  provider = aws.ap
  vpc = true
}

resource "aws_eip" "wsi_natgw_b" {
  provider = aws.ap
  vpc = true
}

resource "aws_route_table" "wsi_app_a_rt" {
  provider = aws.ap
  vpc_id = aws_vpc.wsi_vpc.id
  tags = {
    Name = "wsi-app-a-rt"
  }
}

resource "aws_route_table" "wsi_app_b_rt" {
  provider = aws.ap
  vpc_id = aws_vpc.wsi_vpc.id
  tags = {
    Name = "wsi-app-b-rt"
  }
}

resource "aws_route_table" "wsi_public_rt" {
  provider = aws.ap
  vpc_id = aws_vpc.wsi_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wsi_igw.id
  }
  tags = {
    Name = "wsi-public-rt"
  }
}

resource "aws_route_table" "wsi_data_rt" {
  provider = aws.ap
  vpc_id = aws_vpc.wsi_vpc.id
  tags = {
    Name = "wsi-data-rt"
  }
}

resource "aws_route" "wsi_app_a_nat_route" {
  provider = aws.ap
  route_table_id         = aws_route_table.wsi_app_a_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.wsi_natgw_a.id
}

resource "aws_route" "wsi_app_b_nat_route" {
  provider = aws.ap
  route_table_id         = aws_route_table.wsi_app_b_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.wsi_natgw_b.id
}

resource "aws_route_table_association" "wsi_app_a_assoc" {
  provider = aws.ap
  subnet_id      = aws_subnet.wsi_app_a.id
  route_table_id = aws_route_table.wsi_app_a_rt.id
}

resource "aws_route_table_association" "wsi_app_b_assoc" {
  provider = aws.ap
  subnet_id      = aws_subnet.wsi_app_b.id
  route_table_id = aws_route_table.wsi_app_b_rt.id
}

resource "aws_route_table_association" "wsi_public_a_assoc" {
  provider = aws.ap
  subnet_id      = aws_subnet.wsi_public_a.id
  route_table_id = aws_route_table.wsi_public_rt.id
}

resource "aws_route_table_association" "wsi_public_b_assoc" {
  provider = aws.ap
  subnet_id      = aws_subnet.wsi_public_b.id
  route_table_id = aws_route_table.wsi_public_rt.id
}

resource "aws_route_table_association" "wsi_data_a_assoc" {
  provider = aws.ap
  subnet_id      = aws_subnet.wsi_data_a.id
  route_table_id = aws_route_table.wsi_data_rt.id
}

resource "aws_route_table_association" "wsi_data_b_assoc" {
  provider = aws.ap
  subnet_id      = aws_subnet.wsi_data_b.id
  route_table_id = aws_route_table.wsi_data_rt.id
}

resource "aws_vpc_endpoint" "s3" {
  provider = aws.ap
  vpc_id       = aws_vpc.wsi_vpc.id
  service_name = "com.amazonaws.ap-northeast-2.s3"
  route_table_ids = [
    aws_route_table.wsi_app_a_rt.id,
    aws_route_table.wsi_app_b_rt.id,
    aws_route_table.wsi_public_rt.id,
    aws_route_table.wsi_data_rt.id
  ]
  tags = {
    Name = "s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  provider = aws.ap
  vpc_id       = aws_vpc.wsi_vpc.id
  service_name = "com.amazonaws.ap-northeast-2.dynamodb"
  route_table_ids = [
    aws_route_table.wsi_app_a_rt.id,
    aws_route_table.wsi_app_b_rt.id,
    aws_route_table.wsi_public_rt.id,
    aws_route_table.wsi_data_rt.id
  ]
  tags = {
    Name = "dynamodb-endpoint"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  provider = aws.ap
  name = "/aws/vpc/wsi-vpc"
  tags = {
    Name = "vpc-flow-log-group"
  }
}

resource "aws_flow_log" "vpc_flow_log" {
  provider = aws.ap
  log_group_name = aws_cloudwatch_log_group.vpc_flow_log_group.name
  vpc_id         = aws_vpc.wsi_vpc.id
  traffic_type   = "ALL"
  iam_role_arn   = aws_iam_role.vpc_flow_log_role.arn
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name = "vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  role = aws_iam_role.vpc_flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
