resource "aws_security_group" "employees_sg" {
  name   = "employees-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb.id]  # Strictly allowing traffic coming from the ALB 
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}
