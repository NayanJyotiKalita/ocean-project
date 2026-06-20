# ---------IAM Roles For SSM---------
resource "aws_iam_role" "company_role" {
  name = "company-tenant-role"
  assume_role_policy = jsonencode(
    {
	  "Version": "2012-10-17",
	  "Statement": [
		{
			"Sid": "Statement1",
			"Effect": "Allow",
			"Principal": {
				"Service": "ec2.amazonaws.com"
			},
			"Action": [
				"sts:AssumeRole"
			]
		}
	]
})
}

resource "aws_iam_role_policy_attachment" "compnay_ssm" {
  role = aws_iam_role.company_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "company_profile" {
  name = "Company-Tenant-Profile"
  role = aws_iam_role.company_role.name
}


module "ec2_private_app1" {
  depends_on = [ module.vpc ]
  source     = "terraform-aws-modules/ec2-instance/aws"
  version    = "6.4.0"

  name                   = "${var.environment}-companies"
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  # key_name               = var.keypair   --> not needed as we are using SSM
  user_data_base64       = base64encode(file("app-install.sh"))
  iam_instance_profile   = aws_iam_instance_profile.company_profile.name

  for_each               = toset([for i in range(var.private_instance_count) : tostring(i)])
  subnet_id              = element(module.vpc.private_subnets, tonumber(each.key))
  vpc_security_group_ids = [aws_security_group.companies_sg.id] 


  root_block_device = {
    encrypted  = true     # Encryption of volume fulfilled
    type       = "gp3"
    size       = 10
    tags = {
      Name = "my-root-block-companies"
    }
  }

  tags                   = local.common_tags
}