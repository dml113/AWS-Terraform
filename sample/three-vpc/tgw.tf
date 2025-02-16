resource "aws_ec2_transit_gateway" "my-tgw" {
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  auto_accept_shared_attachments = "enable"
  multicast_support = "disable"

  tags = {
    Name = "my-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "ma-tgw-attach" {
  subnet_ids = [module.managed_vpc.subnet_ids["public-subnet-a"], module.managed_vpc.subnet_ids["public-subnet-b"]]
  transit_gateway_id = aws_ec2_transit_gateway.my-tgw.id
  vpc_id = module.managed_vpc.vpc_id
  tags = {
    Name = "ma-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "my-app-tgw-attach" {
  subnet_ids = [module.application_vpc.subnet_ids["app-subnet-a"], module.application_vpc.subnet_ids["app-subnet-b"]]
  transit_gateway_id = aws_ec2_transit_gateway.my-tgw.id
  vpc_id = module.application_vpc.vpc_id
  tags = {
    Name = "my-app-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "my-db-tgw-attach" {
  subnet_ids = [module.database_vpc.subnet_ids["db-subnet-a"], module.database_vpc.subnet_ids["db-subnet-b"]]
  transit_gateway_id = aws_ec2_transit_gateway.my-tgw.id
  vpc_id = module.database_vpc.vpc_id 
  tags = {
    Name = "my-db-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_route_table" "ma-tgw-rt" {
  transit_gateway_id = aws_ec2_transit_gateway.my-tgw.id 
  tags = {
    Name = "ma-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table" "my-app-tgw-rt" {
  transit_gateway_id = aws_ec2_transit_gateway.my-tgw.id 
  tags = {
    Name = "my-app-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table" "my-db-tgw-rt" {
  transit_gateway_id = aws_ec2_transit_gateway.my-tgw.id 
  tags = {
    Name = "my-db-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "ma-tgw-rt" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.ma-tgw-attach.id 
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ma-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "my-app-tgw-rt" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.my-app-tgw-attach.id 
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.my-app-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "my-db-tgw-rt" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.my-db-tgw-attach.id 
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.my-db-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route" "ma-tgw-rt1" {
  destination_cidr_block         = "172.16.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.my-app-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ma-tgw-rt.id 
}

resource "aws_ec2_transit_gateway_route" "ma-tgw-rt2" {
  destination_cidr_block         = "192.168.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.my-db-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ma-tgw-rt.id 
}

resource "aws_ec2_transit_gateway_route" "my-app-tgw-rt1" {
  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.ma-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.my-app-tgw-rt.id 
}

resource "aws_ec2_transit_gateway_route" "my-app-tgw-rt2" {
  destination_cidr_block         = "192.168.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.my-db-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.my-app-tgw-rt.id 
}

resource "aws_ec2_transit_gateway_route" "my-db-tgw-rt1" {
  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.ma-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.my-db-tgw-rt.id
}

resource "aws_ec2_transit_gateway_route" "my-db-tgw-rt2" {
  destination_cidr_block         = "172.16.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.my-app-tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.my-db-tgw-rt.id 
}