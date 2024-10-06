resource "aws_ec2_transit_gateway" "wsc2024-vpc-tgw" {
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  auto_accept_shared_attachments = "enable"
  multicast_support = "disable"
  transit_gateway_cidr_blocks = ["10.0.2.0/24"]

  tags = {
    Name = "wsc2024-vpc-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "wsc2024-vpc1-tgw-attach" {
  subnet_ids = [aws_subnet.gwangju_VPC1_private_subnet_a.id, aws_subnet.gwangju_VPC1_private_subnet_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
  vpc_id = aws_vpc.gwangju_VPC1.id
  tags = {
    Name = "wsc2024-vpc1-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "wsc2024-vpc2-tgw-attach" {
  subnet_ids = [aws_subnet.gwangju_VPC2_private_subnet_a.id, aws_subnet.gwangju_VPC2_private_subnet_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
  vpc_id = aws_vpc.gwangju_VPC2.id
  tags = {
    Name = "wsc2024-vpc2-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "wsc2024-egress-tgw-attach" {
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
  vpc_id = aws_vpc.vpc.id 
  tags = {
    Name = "wsc2024-egress-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_route_table" "wsc2024-vpc1-tgw-rt" {
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id 
  tags = {
    Name = "wsc2024-vpc1-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table" "wsc2024-vpc2-tgw-rt" {
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id 
  tags = {
    Name = "wsc2024-vpc2-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table" "wsc2024-egress-tgw-rt" {
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id 
  tags = {
    Name = "wsc2024-egress-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "wsc2024-vpc1-tgw-rt" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.wsc2024-vpc1-tgw-attach.id 
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-vpc1-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "wsc2024-vpc2-tgw-rt" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.wsc2024-vpc2-tgw-attach.id 
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-vpc2-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "wsc2024-egress-tgw-rt" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.wsc2024-egress-tgw-attach.id 
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-egress-tgw-rt.id
}