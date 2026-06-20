###Q. Role: 
Acts a senior Cloud DevSecOps Engineer on AWS with 10 years of experience and try to understand the project requirement Outcome: I need you to looks at the security aspects and give me suggestions based on the best security principles needed to be followed

** Context:** You do it in such a manner that the entire company's security is in your hands and you are responsible for it, it there is any discrepancies the company is going to be in huge loss and the security of thousands of customers will be at risk

 **Instructions:** 1. I want you to go through the 2nd task properly and explain me how you would solve the task 2a - database-per-tenant is definitely out of question as it will highly expensive and not much of use generally. Now we are left with the other two option of tenant_id scoping and schema-per-tenant - both looks good but which one would be most efficient and secure in our case.

### Decision: 
We go with schema-per-tenant as the primary model. We do not choose `tenant_id` as the primary model even though it is highly efficient as everything lives in one schema but in a payroll system it could be highly dangerous even if one WHERE tenant_id = .. condition is missed and one buggy join can expose other tenant’s data.

We go with the schema-per-tenant model because it gives a much stronger boundary than row-based scoping. A tenant’s tables are separated at the schema level, so accidental cross-tenant access becomes much harder.

---

### Q
In the 2nd task, we had two things to explain: Show how tenant context is established at login and propagated securely through the request lifecycle • Demonstrate how a query or API call is guaranteed to only return data belonging to the authenticated tenant — no cross-tenant leakage under any condition. I understand the flow of it, help me write it in a structured way

### My Answer Based on its response: 
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

### 1. Establishing Who the User Is (The Digital ID Card)
  - **The Login**: When a user logs in, the system checks their password and hands their browser a highly secure digital ID card (called a JWT).

  - **The Details**: This ID card has their specific `tenant_id` permanently stamped on it. Because it is cryptographically signed, a hacker cannot tamper with it or change their ID to someone else's.

  - **The Handshake**: Every single time the user clicks a button or asks for data, their browser automatically flashes this ID card to your backend server.

  - **The Setup**: Your backend server reads the card, says, "Ah, you belong to Company A," and locks that identity into the server's memory before it processes the request.

### 2. Guaranteeing Zero Data Leaks (The Private Rooms)
  - **The Database Rooms**: Instead of throwing everyone's payroll data into one giant spreadsheet, your PostgreSQL database has completely separate, locked rooms (schemas) for each tenant.

  - **The Guard**: Because your backend knows the user is from Company A (from their digital ID card), it tells the database, "Only unlock the door to Company A's room."

  - **The Guarantee**: Once the system is inside Company A's room, it runs the query. Even if a programmer accidentally writes a sloppy line of code that says "Give me absolutely every payroll record," the database will only return Company A's records. It is physically locked inside that specific room and cannot even see that Company B's room exists.

  - **The File Storage**: The exact same rule applies to the S3 bucket. The AWS IAM policy acts as a strict bouncer, ensuring Company A's server can only ever look inside the `companies/` folder and nowhere else.

---

Q. I have implemented the vpc in the following way, how do I configure the NACL needed to achieve the security compliances:
```
module "vpc" {
source = "terraform-aws-modules/vpc/aws"
version = "6.6.1"
name = "${local.name}-${var.vpc_name}"
cidr = var.vpc_cidr_block
azs = var.vpc_azs
public_subnets = var.vpc_public_subnets
private_subnets = var.vpc_private_subnets
# Database Subnets
database_subnets = var.vpc_database_subnets
create_database_subnet_group = var.vpc_create_database_subnet_group
create_database_subnet_route_table = var.vpc_create_database_subnet_route_table
# NAT Gateways - Outbound Communication (Single NAT in the VPC)
enable_nat_gateway = var.vpc_enable_nat_gateway
single_nat_gateway = var.vpc_single_nat_gateway
one_nat_gateway_per_az = var.vpc_one_nat_gateway_per_az
# VPC DNS Parameters (we can variablise these too)
enable_dns_hostnames = true
enable_dns_support = true
public_dedicated_network_acl = true
private_dedicated_network_acl = true
database_dedicated_network_acl = true
tags = local.common_tags
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
}
```

### Answer:
```
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
```

Above response was actually and was in line with what I was trying to achieve with the NACL 

---


### Q. 
If you go through the Document that I uploaded, you would find in the Task 5, that we are supposed to write a bried incident response runbook on how you would detect, investigate, and recover from a database being accidentally made publicly accessible.

On top of my mind, comes AWS Config Rule i.e. if it detects a state a change, it can trigger an SNS alert, then comes the cloudwatch alarm for rds-high-connection. And to prevent it we can go through the security groups and NACLs and verify all the rules and fix them if changed. Using cloudtrail we can identify who executed the changes and revoking their access.
Is there something that could be done beyond these ways?

### Answer: My answers are a mix of AI and my own thoughts 

#### Detection
  - **AWS Config rule**: AWS Config rule ( rds-instance-public-access-check ) can detect a state change (e.g. `PubliclyAccessible = true`) and trigger an immediate SNS alert to the DevOps team.
  
  - **CloudWatch Alarm**: CloudWatch Alarm (that we set up - rds-high-connections-alarm) would fire if automated internet bots immediately start scanning and probing the exposed port 5432

  - **EventBridge + CloudTrail**: We can create an EventBridge rule which when detects a change can trigger SNS, Lambda - this detects the actual API call
  
  - **GuardDuty**: GuardDuty flags anomalous external IP addresses attempting to communicate with the database. 

  - **Security Hub**: Security Hub aggregates findings from:Config, GuardDuty, IAM Access Analyzer into a centralized dashboard. This is something a security team would actually monitor.

#### Immediate Containment
  - **Lock Down the Security Group**: Immediately navigate to the EC2/VPC console and edit `payroll-rds-sg`. Delete any inbound rules allowing `0.0.0.0/0`. Re-establish the strict binding allowing traffic only from the tenant Security Groups (`company_sg, bureau_sg, employee_sg`). 

  - **Verify NACL Enforcement**: Confirm that the Private Subnet NACL (`Private-DB-NACL`) is still intact. 

  - **Modify RDS Instance**: Use the AWS CLI or Console to modify the RDS instance and explicitly set `PubliclyAccessible = false`. Do not wait for a maintenance window; apply immediately. 

  - **Automated Remediation** : Config Rule
					 → EventBridge
					 → Lambda

Lambda automatically:
```
Remove public accessibility
Restore approved SG
Send SNS alert
```
before a human even starts investigating.

### Investigation
  - **Identify the Actor**: Query AWS CloudTrail for `AuthorizeSecurityGroupIngress` or `ModifyDBInstance` events within the incident timeframe. Identify the IAM User or Role that executed the change. 
  
IAM Review
Check:
```
Was role overprivileged?
Was MFA enabled?
Was this accidental?
Was credentials compromised?
```

- **Determine Data Compromise**: * Query VPC Flow Logs for the database ENI (Elastic Network Interface) to see if any traffic from outside the `10.0.0.0/16` CIDR block was actually accepted. 

- **Suspend Access**: Temporarily revoke the AWS console and API access of the IAM entity that caused the breach until the investigation concludes. 

**Data Classification**
Was exposed data:
```
Employee names
Salary information
Bank details
NI numbers
This affects regulatory response.
For UK GDPR this matters a lot.
```

### Recovery & Remediation 
  - **Rotate Secrets**: Even if no data exfiltration is confirmed, assume the credentials were conceptually at risk. Immediately force a rotation of the RDS master password via AWS Secrets Manager.

  - **Cycle Connections**: Restart the backend EC2 container applications to force them to fetch the newly rotated database credentials and establish fresh, secure connections.

  - **Restore Known Good State**: Terraform can help restore the last approved configuration.

### Post-Incident Improvements 

SCP (Service Control Policy) - Prevent creation of public RDS instances.

E.g. :
```Deny:
rds:ModifyDBInstance
if PubliclyAccessible = true
```
Now even administrators cannot accidentally expose the DB. 

**UK GDPR Escalation**: If VPC Flow Logs or DB Logs confirm that external actors successfully authenticated and accessed the data, immediately notify the Data Protection Officer (DPO). Under UK GDPR, the ICO (Information Commissioner's Office) must be notified within 72 hours of discovering a breach of PII/financial data.
