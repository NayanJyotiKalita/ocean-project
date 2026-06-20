# 1. Architecture Diagram

  1. We have created a VPC with three subnets for a three-tier architecture - one public, one private and one database with two availability Zones
  2. We have provisioned EC2 instances (t2.micro) for running the backend services (1 instance of each tenant type in each AZ for HA), isolating the compute layer
  3. RDS (PostgreSQL, db.t3.micro is provisioned in the database layer with high isolation  
  4. S3 bucket is provisioned with versioning enabled
  5. Each tenant is scoped with IAM roles to enforce access boundaries
  6. Strict security groups and NACLs are configured to isolate the traffic between tenant environments

---

# 2. Multi-Tenancy Architecture
## 2a. Tenant Isolation Strategy 
### 1. Tenancy Model - schema-per-tenant
```
We go with schema-per-tenant as the primary model. We do not choose `tenant_id` as the primary model even though it
is highly efficient as everything lives in one schema but in a payroll system it could be highly dangerous even if
one `WHERE tenant_id = .. ` condition is missed and one buggy join can expose other tenant’s data.

We go with the schema-per-tenant model because it gives a much stronger boundary than row-based scoping. A tenant’s
tables are separated at the schema level, so accidental cross-tenant access becomes much harder.
```

### 2. Establishing Who the User Is (The Digital ID Card)
**The Login**: When a user logs in, the system checks their password and hands their browser a highly secure digital ID card (called a JWT). </br>
**The Details**: This ID card has their specific `tenant_id` permanently stamped on it. Because it is cryptographically signed, a hacker cannot tamper with it or change their ID to someone else's. </br>
**The Handshake**: Every single time the user clicks a button or asks for data, their browser automatically flashes this ID card to your backend server. </br>
**The Setup**: Your backend server reads the card, says, "Ah, you belong to Company A," and locks that identity into the server's memory before it processes the request. </br>

**Flow**
```
User
  |
  v
Login
  |
  v
JWT Issued
(tenant_id embedded)
  |
  v
API Request
  |
  v
Auth Middleware
  |
  +--> Validate JWT
  |
  +--> Extract tenant_id
  |
  v
Application Layer
  |
  v
Database Session
SET app.tenant_id
  |
  v
Query Execution
  |
  v
Tenant Data Returned
```

### 3. Guaranteeing Zero Data Leaks (The Private Rooms)
  - **The Database Rooms**: Instead of throwing everyone's payroll data into one giant spreadsheet, your PostgreSQL database has completely separate, locked rooms (schemas) for each tenant. </br>
  - **The Guard**: Because your backend knows the user is from Company A (from their digital ID card), it tells the database, "Only unlock the door to Company A's room." </br>
  - **The Guarantee**: Once the system is inside Company A's room, it runs the query. Even if a programmer accidentally writes a sloppy line of code that says "Give me absolutely every payroll record," the database will only return Company A's records. It is physically locked inside that specific room and cannot even see that Company B's room exists. </br>
  - **The File Storage**: The exact same rule applies to the S3 bucket. The AWS IAM policy acts as a strict bouncer, ensuring Company A's server can only ever look inside the `companies/` folder and nowhere else. </br>

## 2b. Access Boundaries at the Infrastructure Layer
#### 1. Separate IAM roles are for each portal with strict access limit is defined for their respective AWS resources
e.g.
```hcl
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
```

#### 2. S3 bucket policies and prefixes has been enforced so that no portal can access other portal’s documents:
```hcl
data "aws_caller_identity" "current" {}


# -------S3 Bucket-------
resource "aws_s3_bucket" "ocean-documents" {
  bucket        = "ocean-docs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}


resource "aws_s3_bucket_versioning" "documents_versioning" {
  bucket = aws_s3_bucket.ocean-documents.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "document_encryption" {
  bucket = aws_s3_bucket.ocean-documents.id
  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
        }
    }
}


# --- TENANT ISOLATION POLICIES ---


# 1. Company Boundary
resource "aws_iam_role_policy" "company_s3_policy" {
  name = "Company-S3-Policy"
  role = aws_iam_role.company_role.id


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
        # ONLY allow access to the 'companies/' folder
        Resource = "${aws_s3_bucket.ocean_documents.arn}/companies/*"
      }
    ]
  })
}


# 2. Bureau Boundary
resource "aws_iam_role_policy" "bureau_s3_policy" {
  name = "Bureau-S3-Policy"
  role = aws_iam_role.bureaus_role.id


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
        # ONLY allow access to the 'bureaus/' folder
        Resource = "${aws_s3_bucket.ocean_documents.arn}/bureaus/*"
      }
    ]
  })
}


# 3. Employee Boundary
resource "aws_iam_role_policy" "employee_s3_policy" {
  name = "Employee-S3-Policy"
  role = aws_iam_role.employee_role.id


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
        # ONLY allow access to the 'bureaus/' folder
        Resource = "${aws_s3_bucket.ocean_documents.arn}/employees/*"
      }
    ]
  })
}
```

## 2c. Tenant Onboarding & Offboarding
### Onboarding: 
As soon as a new Company or Bureau is provisioned in the system, they need to get a workspace that is completely isolated from everyone else.

So instead of putting their data into some pre-existing schema, they are provisioned with their own Schema and a their own document storing/accessing file (S3/prefix)

Along with this, they new tenant gets their IAM Role and login token which has only the required permissions scoped to it so that the new tenant cannot cross their boundaries and is automatically blocked if tries to access

### Offboarding: 
Once the tenant leaves, all the data related to it, should be erased completely. First of all the IAM role and the login token will be deactivated so that the tenant can never log back in. Then we completely erase anything that they generated like the S3 files and their entire Schema will be deleted. 

---

# 3. Security & Access Control
## 3a. IAM & Role-Based Access Control

IAM roles and policies are created to enforce least-privilege access </br>

Separate access boundaries for all three tenants are defined - no one has access to resources outside its boundary </br>

No hardcoded credentials are present anywhere whatsoever </br>


## 3b. Secrets Management

Database credentials are auto-generated via Terraform (`manage_master_user_password = true`) and stored directly in AWS Secrets Manager. </br>

DB password, AWS Access Keys, Secret Keys are all stored in the GitHub Vault securely and can be fetched directly from there without any hardcoding needed </br>


## 3c. Encryption

RDS and S3 (even the root block devices of EC2 instances) are encrypted at rest </br>

SSL/TLS configured for all the services exposed over the network: the security groups were all configured with the ingress rule for Port 443(HTTPS) and for the Public NACL also, we have configured the inbound rule coming from the internet via Port 443. </br>

Data in transit is protected between services - The Application Load Balancer (ALB) is configured with an HTTPS listener (Port 443) using an AWS Certificate Manager (ACM) TLS certificate to encrypt the data between the client and the VPC boundary. HTTP traffic is strictly redirected to HTTPS. </br>

## 3d. Network Security 

Security Groups and NACL are configured with high security measures </br>

Database and Internal services are not public accessible </br>

Preventing one tenant's traffic from reaching another tenant's compute or data layer - We achieved this by provisioning three completely separate Security Groups for the compute layer - companies_sg, bureaus_sg and employees_sg. We have configured them in such a way that there is zero ingress rules allowing these groups to communicate with one another. Any traffic (if by some reason) tries to go from the Company EC2 to the Bureaus EC2, the traffic is dropped immediately. Even though we have an RDS instance, network access to it is very strict. The rds_sg Security Group is configured with ingress rules that only accepts traffic on Port 5432 coming only from the three authorized tenant Security Groups:

```hcl
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
```

If any tenant attempts to ping the database on any other post, or if any unauthorized internal server attempt to reach the database, the network drops the connection

---

# 4. CI/CD Pipeline 

We wrote a CI/CD pipeline in GitHub Actions that:
  - Runs on every push to the main branch
  - Builds and tests a simple Dockerised application 
  - Deploys to an EC2 instance using SSH or AWS Systems Manager (SSM) — no paid container registry required
  - Handles environment-specific configurations
    
The pipeline also runs in such a way that multiple teams (frontent, backend, AI, etc) can independently trigger deployments to their respective services without interfering with each other here: [deploy-backent.yml](/.github/workflows/deploy-backend.yml)

---

# 5. Monitoring & Incident Readiness

We have succesfully:
  - Configured CloudWatch alarms for EC2 CPU utilisation and RDS connection thresholds
  - Set up CloudWatch log groups for application and infrastructure logs - Logs are retained for 30 days. Indefinite log storage quickly incurs AWS charges
  - Defined SNS alerts that would notify the team of a critical failure

---

# 6. UK Compliance Considerations

## 1. AWS-Native Controls for UK GDPR Compliance (PII & Bank Data) 
To ensure strict compliance with UK GDPR Article 32 (Security of Processing), the following AWS-native controls are implemented:

  - **Encryption at Rest & in Transit**: All S3 buckets and RDS volumes are encrypted at rest using AWS KMS (Key Management Service) with AES-256. All data in transit is encrypted via AWS ACM (TLS for external traffic) and native PostgreSQL SSL for internal VPC traffic.

  - **Access Auditing**: AWS CloudTrail is enabled to log every API call made against the infrastructure. This guarantees an immutable audit trail of who accessed or modified data resources, fulfilling the GDPR accountability principle.

  - **PII Discovery**: Amazon Macie can be enabled on the `ocean-documents` S3 bucket to continuously scan for and alert on improperly stored PII or financial data (e.g., accidentally uploading unencrypted bank details).

  - **Least Privilege**: Strict IAM Roles and S3 Prefix policies ensure that no application or user has standing access to data outside their explicit scope.

## 2. Ensuring Data Residency (UK/EU Region) 
UK GDPR mandates that data must not be transferred outside the UK/EEA without adequate safeguards. To guarantee data residency:

  - **Infrastructure Deployment**: All infrastructure, as defined in our Terraform state and CI/CD pipelines, is strictly hardcoded to deploy to the `eu-west-2` (London) region.

  - **Preventative Guardrails**: To prevent human error or shadow IT, we would implement AWS Organizations Service Control Policies (SCPs). An SCP would be attached at the root account level explicitly denying any `sts:AssumeRole` or resource creation actions (like `ec2:RunInstances` or `s3:CreateBucket`) in any region other than `eu-west-2`.

## 3. Handling the Right to Erasure (Permanent Deletion) 
When an employee invokes their UK GDPR Article 17 "Right to Erasure" (Right to be Forgotten), the system executes a strict offboarding protocol:

  - **Active Data Deletion**: An automated process executes a hard DELETE on the employee's relational data within the PostgreSQL database and permanently deletes their corresponding prefix (e.g., `s3://[bucket-name]/employees/[employee_id]/`) from S3. We do not just put their files in a "Recycle Bin" (soft delete). We run an automated script that permanently incinerates their S3 filing cabinet and completely demolishes their database room (`DROP SCHEMA CASCADE`). The data is permanently erased.

  - **Handling Backups/Snapshots**: Because it is technically impossible to surgically remove a single employee's record from an immutable RDS automated snapshot, the platform relies on a "Put Beyond Use" policy. The data remains securely encrypted in the backup until the snapshot naturally ages out and is destroyed by the standard 30-day retention lifecycle.

  - **Suppression List**: The employee's ID is added to a cryptographic hash suppression list. In the highly unlikely event that a database snapshot needs to be restored, this list acts as an automated filter to immediately re-delete the user's data upon restoration, satisfying ICO guidelines for backup compliance.


---







