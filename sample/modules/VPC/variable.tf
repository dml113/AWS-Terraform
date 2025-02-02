variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "create_igw" {
  description = "Whether to create an Internet Gateway"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "Subnet definitions"
  type = map(object({
    name   = string
    cidr   = string
    az     = string
    public = bool
  }))
}

variable "nat_gateways" {
  description = "NAT Gateway definitions"
  type = map(object({
    name      = string
    subnet_id = string
  }))
  default = {}
}

variable "route_tables" {
  description = "Route Table definitions"
  type        = map(string)
}

variable "routes" {
  description = "Route definitions"
  type = map(object({
    rt_name         = string
    cidr            = string
    gateway_id      = optional(string)
    nat_gateway_key = optional(string)
  }))
  default = {}
}

variable "subnet_associations" {
  description = "Associations between subnets and route tables"
  type = map(object({
    subnet_key      = string
    route_table_key = string
  }))
}
