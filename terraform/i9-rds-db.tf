resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "my-rds-db"
  identifier           = "ocean-db"
  engine               = "postgres"
  engine_version       = "17"
  instance_class       = "db.t3.micro"
  username             = "ocean-admin"
  
  manage_master_user_password = true   # Task 3b - No secret hardcoding

  # Task 3d - Isolation
  db_subnet_group_name        = module.vpc.database_subnet_group_name
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]
  publicly_accessible         = false

  # ENcryption at Rest (Task 3c)
  storage_encrypted    = true

  tags = local.common_tags
}
