variable "vpc_name" {
  description = "The name for the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnets_cidr" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
}

variable "private_subnets_cidr" {
  description = "The CIDR blocks for the private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "The availability zones for subnets"
  type        = list(string)
}

variable "public_subnet_names" {
  description = "Names for the public subnets"
  type        = list(string)
}

variable "private_subnet_names" {
  description = "Names for the private subnets"
  type        = list(string)
}

variable "igw_name" {
  description = "Name for the internet gateway"
  type        = string
}

variable "nat_eip_names" {
  description = "Names for the NAT gateway EIPs"
  type        = list(string)
}

variable "nat_gw_names" {
  description = "Names for the NAT gateways"
  type        = list(string)
}

variable "public_route_table_name" {
  description = "Name for the public route table"
  type        = string
}

variable "private_route_table_names" {
  description = "Names for the private route tables"
  type        = list(string)
}