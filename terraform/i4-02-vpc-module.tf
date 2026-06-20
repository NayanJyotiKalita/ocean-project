module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name             = "${local.name}-${var.vpc_name}"
  cidr             = var.vpc_cidr_block
  azs              = var.vpc_azs
  public_subnets   = var.vpc_public_subnets
  private_subnets  = var.vpc_private_subnets
  
  # Database Subnets
  database_subnets                    = var.vpc_database_subnets
  create_database_subnet_group        = var.vpc_create_database_subnet_group
  create_database_subnet_route_table  = var.vpc_create_database_subnet_route_table

  # NAT Gateways - Outbound Communication (Single NAT in the VPC)
  enable_nat_gateway     = var.vpc_enable_nat_gateway
  single_nat_gateway     = var.vpc_single_nat_gateway
  one_nat_gateway_per_az = var.vpc_one_nat_gateway_per_az

  # VPC DNS Parameters (we can variablise these too)
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_dedicated_network_acl   = true
  private_dedicated_network_acl  = true
  database_dedicated_network_acl = true

  tags     = local.common_tags
  vpc_tags = local.common_tags

  public_subnet_tags = {
    type = "public-subnets"
  }
  
  private_subnet_tags = {
    type = "private-subnets"
  }

  database_subnet_tags = {
    type = "database-subnets"
  }


# ---------------------------------------
  # 1. PUBLIC NACL RULES (ALB & NAT Layer)
  # ---------------------------------------
  public_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0" # Allow HTTPS from Internet to ALB
    },
    {
      rule_number = 110
      rule_action = "allow"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0" # Allow return traffic
    }
  ]

  public_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_block  = var.vpc_cidr_block  # Allow ALB to send traffic within the VPC
    },
    {
      rule_number = 110
      rule_action = "allow"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0" # Allow NAT to reach the internet
    },
    {
      rule_number = 120
      rule_action = "allow"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0" # Allow return traffic to internet clients
    }
  ]

  # ---------------------------------------------------------
  # 2. PRIVATE NACL RULES (Tenant Compute Layer)
  # ---------------------------------------------------------
  private_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_block  = var.vpc_public_subnets[0] # Allow ALB traffic from Public Subnet A
    },
    {
      rule_number = 110
      rule_action = "allow"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_block  = var.vpc_public_subnets[1] # Allow ALB traffic from Public Subnet B
    },
    {
      rule_number = 120
      rule_action = "allow"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0" # Allow return traffic from NAT/Internet
    }
  ]

  private_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0" # Allow outbound to NAT (for SSM and Docker pulls)
    },
    {
      rule_number = 110
      rule_action = "allow"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_block  = var.vpc_database_subnets[0] # Allow outbound to DB Subnet A
    },
    {
      rule_number = 120
      rule_action = "allow"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_block  = var.vpc_database_subnets[1] # Allow outbound to DB Subnet B
    },
    {
      rule_number = 130
      rule_action = "allow"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = var.vpc_cidr_block # Allow return web traffic to ALB
    }
  ]

  # ---------------------------------------------------------
  # 3. DATABASE NACL RULES (Most Restrictive)
  # ---------------------------------------------------------
  database_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_block  = var.vpc_private_subnets[0] # Allow from Private Subnet A
    },
    {
      rule_number = 110
      rule_action = "allow"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_block  = var.vpc_private_subnets[1] # Allow from Private Subnet B
    }
  ]

  database_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = var.vpc_cidr_block # Allow ephemeral return traffic back to VPC
    }
  ]
}

