resource "aws_security_group" "rds_sg" {
  name = "rds-sg"
  vpc_id = module.vpc.vpc_id
  
  ingress = {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    
    # Strictly Allowing traffic on 5432 only from instances belonging to the follwing Security Groups
    security_groups = [
        aws_security_group.companies_sg.id,
        aws_security_group.bureaus_sg.id,
        aws_security_group.employees_sg.id ]   
  }

  tags = local.common_tags
}

