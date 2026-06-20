# AWS EC2 Security Group Terraform Outputs

# Private EC2 Instances Security Group Outputs
## private_sg_group_id
output "private_company_sg_group_id" {
  description = "The ID of the security group"
  value = aws_security_group.companies_sg.id
}

output "private_bureau_sg_group_id" {
  description = "The ID of the security group"
  value = aws_security_group.bureaus_sg.id
}

output "private_employee_sg_group_id" {
  description = "The ID of the security group"
  value = aws_security_group.employees_sg.id
}

## private_sg_group_vpc_id
output "private_sg_group_vpc_id" {
  description = "VPC ID"
  value = aws_security_group.companies_sg.vpc_id
}


# Loadbalancer Security Group Outputs
## alb_sg_id
output "alb_sg_group_id" {
  description = "The ID of the security group"
  value = aws_security_group.alb_sg.id
}

## alb_sg_group_vpc_id
output "alb_sg_group_vpc_id" {
  description = "VPC ID"
  value = aws_security_group.alb_sg.vpc_id
}

## alb_sg_group_name
output "alb_sg_group_name" {
  description = "The name of the security group"
  value = aws_security_group.companies_sg.name
}
