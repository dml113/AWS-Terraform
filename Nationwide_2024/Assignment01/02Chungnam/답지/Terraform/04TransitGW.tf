resource "aws_ec2_transit_gateway" "wsc2024-vpc-tgw" {
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  auto_accept_shared_attachments = "enable"
  multicast_support = "disable"
  transit_gateway_cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16", "192.168.0.0/16"]

  tags = {
    Name = "wsc2024-vpc-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "wsc2024-ma-tgw-attach" {
  subnet_ids = [aws_subnet.wsc2024-ma-mgmt-sn-a.id, aws_subnet.wsc2024-ma-mgmt-sn-b.id]
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
  vpc_id = aws_vpc.wsc2024-ma-vpc.id 
  tags = {
    Name = "wsc2024-ma-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "wsc2024-prod-tgw-attach" {
  subnet_ids = [aws_subnet.wsc2024-prod-load-sn-a.id, aws_subnet.wsc2024-prod-load-sn-b.id]
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
  vpc_id = aws_vpc.wsc2024-prod-vpc.id
  tags = {
    Name = "wsc2024-prod-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "wsc2024-storage-tgw-attach" {
  subnet_ids = [aws_subnet.wsc2024-storage-db-sn-a.id, aws_subnet.wsc2024-storage-db-sn-b.id]
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
  vpc_id = aws_vpc.wsc2024-storage-vpc.id 
  tags = {
    Name = "wsc2024-storage-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_route_table" "wsc2024-ma-tgw-rt" {
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id 
  tags = {
    Name = "wsc2024-ma-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table" "wsc2024-prod-tgw-rt" {
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id 
  tags = {
    Name = "wsc2024-prod-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table" "wsc2024-storage-tgw-rt" {
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id 
  tags = {
    Name = "wsc2024-storage-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "wsc2024-ma-tgw-rt" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.wsc2024-ma-tgw-attach.id 
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-ma-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "wsc2024-prod-tgw-rt" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.wsc2024-prod-tgw-attach.id 
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-prod-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "wsc2024-storage-tgw-rt" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.wsc2024-storage-tgw-attach.id 
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-storage-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route" "wsc2024-ma-tgw-rt1" {
  destination_cidr_block         = "172.16.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-prod-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-ma-tgw-rt.id 
}

resource "aws_ec2_transit_gateway_route" "wsc2024-ma-tgw-rt2" {
  destination_cidr_block         = "192.168.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-storage-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-ma-tgw-rt.id 
}

resource "aws_ec2_transit_gateway_route" "wsc2024-prod-tgw-rt1" {
  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-ma-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-prod-tgw-rt.id 
}

resource "aws_ec2_transit_gateway_route" "wsc2024-prod-tgw-rt2" {
  destination_cidr_block         = "192.168.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-storage-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-prod-tgw-rt.id 
}

resource "aws_ec2_transit_gateway_route" "wsc2024-storage-tgw-rt1" {
  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-ma-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-storage-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route" "wsc2024-storage-tgw-rt2" {
  destination_cidr_block         = "172.16.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-prod-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-storage-tgw-rt.id 
}