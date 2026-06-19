# VPC Input Variables

# VPC Name
variable "vpc_name" {
  description = "VPC Name"
  type = string
  default = "my-vpc"
}

# VPC CIDR Block
variable "vpc_cidr_block" {
  description = "VPC CIDR Block"
  type = string
  default = "10.0.0.0/16"
}

# VPC Availability Zones
variable "vpc_azs" {
  description = "VPC Availability Zones"
  type = list(string)
  default = ["us-west-2a", "us-west-2b"]
}

# VPC Public Subnets
variable "vpc_public_subnets" {
  description = "VPC Public Subnets"
  type = list(string)
  default = [ "10.0.1.0/24", "10.0.2.0/24" ]
}

# VPC Private Subnets
variable "vpc_private_subnets" {
  description = "VPC Private Subnets"
  type = list(string)
  default = [ "10.0.11.0/24", "10.0.12.0/24" ]
}

# VPC Database Subnets
variable "vpc_database_subnets" {
  description = "VPC Database Subnets"
  type = list(string)
  default = [ "10.0.21.0/24", "10.0.22.0/24" ]
}

# VPC Create Database Subnet Group (True / False)
variable "vpc_create_database_subnet_group" {
  description = "VPC Create Database Subnet Group"
  type = bool
  default = true
}

# VPC Create Database Subnet Route Table (True or False)
variable "vpc_create_database_subnet_route_table" {
  description = "VPC Create Database Subnet Route Table"
  type = bool
  default = true
}

# VPC Enable NAT Gateway (True or False) 
variable "vpc_enable_nat_gateway" {
  description = "Enable NAT Gateways for Private Subnets Outbound Communication"
  type = string
  default = true
}

# VPC Single NAT Gateway (True or False)
variable "vpc_single_nat_gateway" {
  description = "Enable only single NAT Gateway in one Availability Zone to save costs during our demos"
  type = bool
  default = true  # We have changed this value here as compared to the last example as we need only one nat
}

# VPC One NAT Gateway per AZ (True or False)
variable "vpc_one_nat_gateway_per_az" {
  description = "Enable one NAT Gateway in each Availabilty Zone for smoother communication in production env"
  type = bool
  default = false  # We have changed this value too due to the same reason as we need don't one nat in each az
}