# ---------IAM Roles For SSM---------
resource "aws_iam_role" "bureaus_role" {
  name = "bureaus-tenant-role"
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
}
  )
}

resource "aws_iam_role_policy_attachment" "bureaus_ssm" {
  role = aws_iam_role.bureaus_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bureaus_profile" {
  name = "Bureaus-Tenant-Profile"
  role = aws_iam_role.bureaus_role.name
}

# Instance Provisioning
module "ec2_private_app2" {
  depends_on = [ module.vpc ]
  source     = "terraform-aws-modules/ec2-instance/aws"
  version    = "6.4.0"

  name                   = "${var.environment}-bureaus"
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  # key_name               = var.keypair 
  user_data_base64       = base64encode(file("app-install-2-bureaus.sh"))
  iam_instance_profile   = aws_iam_instance_profile.bureaus_profile.name 

  for_each               = toset([for i in range(var.private_instance_count) : tostring(i)])
  subnet_id              = element(module.vpc.private_subnets, tonumber(each.key))
  vpc_security_group_ids = [aws_security_group.bureaus_sg.id]

  root_block_device = {
    encrypted  = true     # Encryption of volume fulfilled
    type       = "gp3"
    size       = 10
    tags = {
      Name = "my-root-block-bureaus"
    }
  }

  tags  = local.common_tags
}
