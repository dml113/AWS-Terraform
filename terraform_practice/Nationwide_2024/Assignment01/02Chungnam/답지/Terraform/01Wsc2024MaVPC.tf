#
# Create VPC
#
resource "aws_vpc" "wsc2024-ma-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "wsc2024-ma-vpc"
  }
}

#
# Create Flow Log
#
resource "aws_flow_log" "wsc2024-ma-vpc-flowlog" {
  iam_role_arn    = aws_iam_role.wsc2024-ma-flowlog_role.arn
  log_destination = aws_cloudwatch_log_group.wsc2024-ma-flowlog_cloudwatch.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.wsc2024-ma-vpc.id
}

resource "aws_cloudwatch_log_group" "wsc2024-ma-flowlog_cloudwatch" {
  name = "wsc2024-ma-vpc-flowlogs-log-group"
}

data "aws_iam_policy_document" "wsc2024-ma-assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "wsc2024-ma-flowlog_role" {
  name               = "wsc2024-ma-vpc-flowlogs-role"
  assume_role_policy = data.aws_iam_policy_document.wsc2024-ma-assume_role.json
}

data "aws_iam_policy_document" "wsc2024-ma-flowlog_policy_json" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "wsc2024-ma-flowlog_policy" {
  name   = "wsc2024-ma-vpc-flowlogs-policy"
  role   = aws_iam_role.wsc2024-ma-flowlog_role.id
  policy = data.aws_iam_policy_document.wsc2024-ma-flowlog_policy_json.json
}

#
# Create Public Subnet
#
resource "aws_subnet" "wsc2024-ma-mgmt-sn-a" {
  vpc_id     = aws_vpc.wsc2024-ma-vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  map_public_ip_on_launch = true

  tags = {
    Name = "wsc2024-ma-mgmt-sn-a"
  }
}

resource "aws_subnet" "wsc2024-ma-mgmt-sn-b" {
  vpc_id     = aws_vpc.wsc2024-ma-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  map_public_ip_on_launch = true

  tags = {
    Name = "wsc2024-ma-mgmt-sn-b"
  }
}

#
# Create Internet Gateway
#
resource "aws_internet_gateway" "wsc2024-ma-igw" {
  vpc_id = aws_vpc.wsc2024-ma-vpc.id

  tags = {
    Name = "wsc2024-ma-igw"
  }
}

#
# Create EIP
#
resource "aws_eip" "wsc2024-ma-eip_a" {
  domain = "vpc"

  tags = {
    Name = "wsc2024-ma-eip-a"
  }
}

resource "aws_eip" "wsc2024-ma-eip_b" {
  domain = "vpc"

  tags = {
    Name = "wsc2024-ma-eip-b"
  }
}

#
# Create Management Route Table
#
resource "aws_route_table" "wsc2024-ma-mgmt-rt" {
  vpc_id = aws_vpc.wsc2024-ma-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wsc2024-ma-igw.id
  }

  tags = {
    Name = "wsc2024-ma-mgmt-rt"
  }
}

resource "aws_route" "ma_mgmt_route1" {
  route_table_id           = aws_route_table.wsc2024-ma-mgmt-rt.id
  destination_cidr_block   = "172.16.0.0/16"
  transit_gateway_id       = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
}

resource "aws_route" "ma_mgmt_route2" {
  route_table_id           = aws_route_table.wsc2024-ma-mgmt-rt.id
  destination_cidr_block   = "192.168.0.0/16"
  transit_gateway_id       = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
}

resource "aws_route_table_association" "wsc2024-ma-mgmt_association_a" {
  subnet_id      = aws_subnet.wsc2024-ma-mgmt-sn-a.id
  route_table_id = aws_route_table.wsc2024-ma-mgmt-rt.id
}

resource "aws_route_table_association" "wsc2024-ma-mgmt_association_b" {
  subnet_id      = aws_subnet.wsc2024-ma-mgmt-sn-b.id
  route_table_id = aws_route_table.wsc2024-ma-mgmt-rt.id
}

#
# Create S3 VPC Endpoint
#
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id          = aws_vpc.wsc2024-ma-vpc.id
  service_name    = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "*",
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::prod-us-east-1-starport-layer-bucket/*"
    }
  ]
}
POLICY

  route_table_ids = [
    aws_route_table.wsc2024-ma-mgmt-rt.id,
  ]
}