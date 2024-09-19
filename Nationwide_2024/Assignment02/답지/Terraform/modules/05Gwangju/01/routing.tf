resource "aws_route" "vpc1_route1" {
  route_table_id            = aws_route_table.gwangju_VPC1_private_rt-a.id
  destination_cidr_block    = "0.0.0.0/0"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
}

resource "aws_route" "vpc1_route2" {
  route_table_id            = aws_route_table.gwangju_VPC1_private_rt-b.id
  destination_cidr_block    = "0.0.0.0/0"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
}

resource "aws_route" "vpc2_route1" {
  route_table_id            = aws_route_table.gwangju_VPC2_private_rt-a.id
  destination_cidr_block    = "0.0.0.0/0"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
}

resource "aws_route" "vpc2_route2" {
  route_table_id            = aws_route_table.gwangju_VPC2_private_rt-b.id
  destination_cidr_block    = "0.0.0.0/0"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
}

resource "aws_route" "egress_route1" {
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = "10.0.0.0/24"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
}


resource "aws_route" "egress_route2" {
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = "10.0.1.0/24"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
}

resource "aws_route" "egress_route3" {
  route_table_id            = aws_route_table.private_rt-a.id
  destination_cidr_block    = "10.0.0.0/24"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
}

resource "aws_route" "egress_route4" {
  route_table_id            = aws_route_table.private_rt-a.id
  destination_cidr_block    = "10.0.1.0/24"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id
}













resource "aws_ec2_transit_gateway_route" "wsc2024-vpc1-tgw-rt1" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-egress-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-vpc1-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route" "wsc2024-vpc1-tgw-rt2" {
  destination_cidr_block         = "10.0.1.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-vpc1-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-vpc1-tgw-rt.id
}


resource "aws_ec2_transit_gateway_route" "wsc2024-vpc2-tgw-rt1" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-egress-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-vpc2-tgw-rt.id 
}

resource "aws_ec2_transit_gateway_route" "wsc2024-vpc2-tgw-rt2" {
  destination_cidr_block         = "10.0.0.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-vpc2-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-vpc2-tgw-rt.id 
}

resource "aws_ec2_transit_gateway_route" "wsc2024-vpc2-tgw-rt3" {
  destination_cidr_block         = "10.0.2.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-vpc2-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-vpc2-tgw-rt.id 
}

resource "aws_ec2_transit_gateway_route" "wsc2024-egress-tgw-rt1" {
  destination_cidr_block         = "10.0.0.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-vpc1-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-egress-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route" "wsc2024-egress-tgw-rt2" {
  destination_cidr_block         = "10.0.1.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.wsc2024-vpc2-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.wsc2024-egress-tgw-rt.id 
}