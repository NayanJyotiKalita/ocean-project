# Incident Response Runbook: Database Accidentally Made Publicly Accessible

## 1. Detection

### AWS Config Rule

AWS Config rule (`rds-instance-public-access-check`) can detect a state change (e.g. `PubliclyAccessible = true`) and trigger an immediate SNS alert to the DevOps team.

### CloudWatch Alarm

CloudWatch Alarm (that we set up - `rds-high-connections-alarm`) would fire if automated internet bots immediately start scanning and probing the exposed port `5432`.

### EventBridge + CloudTrail

We can create an EventBridge rule which, when it detects a change, can trigger:

* SNS
* Lambda

This detects the actual API call.

### GuardDuty

GuardDuty flags anomalous external IP addresses attempting to communicate with the database.

### Security Hub

Security Hub aggregates findings from:

* Config
* GuardDuty
* IAM Access Analyzer

into a centralized dashboard. This is something a security team would actually monitor.

---

## 2. Immediate Containment

### Lock Down the Security Group

Immediately navigate to the EC2/VPC console and edit `payroll-rds-sg`.

Delete any inbound rules allowing:

```text
0.0.0.0/0
```

Re-establish the strict binding allowing traffic only from the tenant Security Groups:

```text
company_sg
bureau_sg
employee_sg
```

### Verify NACL Enforcement

Confirm that the Private Subnet NACL (`Private-DB-NACL`) is still intact.

### Modify RDS Instance

Use the AWS CLI or Console to modify the RDS instance and explicitly set:

```text
PubliclyAccessible = false
```

Do not wait for a maintenance window; apply immediately.

### Automated Remediation

```text
Config Rule
    ↓
EventBridge
    ↓
Lambda
```

Lambda automatically:

```text
Remove public accessibility
Restore approved SG
Send SNS alert
```

before a human even starts investigating.

---

## 3. Investigation

### Identify the Actor

Query AWS CloudTrail for:

* `AuthorizeSecurityGroupIngress`
* `ModifyDBInstance`

events within the incident timeframe.

Identify the IAM User or Role that executed the change.

### IAM Review

Check:

* Was role overprivileged?
* Was MFA enabled?
* Was this accidental?
* Was credentials compromised?

### Determine Data Compromise

Query VPC Flow Logs for the database ENI (Elastic Network Interface) to see if any traffic from outside the `10.0.0.0/16` CIDR block was actually accepted.

### Suspend Access

Temporarily revoke the AWS console and API access of the IAM entity that caused the breach until the investigation concludes.

### Data Classification

Was exposed data:

* Employee names
* Salary information
* Bank details
* NI numbers

This affects regulatory response.

For UK GDPR this matters a lot.

---

## 4. Recovery & Remediation

### Rotate Secrets

Even if no data exfiltration is confirmed, assume the credentials were conceptually at risk.

Immediately force a rotation of the RDS master password via AWS Secrets Manager.

### Cycle Connections

Restart the backend EC2 container applications to force them to fetch the newly rotated database credentials and establish fresh, secure connections.

### Restore Known Good State

Terraform can help restore the last approved configuration.

---

## 5. Post-Incident Improvements

### SCP (Service Control Policy)

Prevent creation of public RDS instances.

Example:

```text
Deny:
rds:ModifyDBInstance
if PubliclyAccessible = true
```

Now even administrators cannot accidentally expose the DB.

### UK GDPR Escalation

If VPC Flow Logs or DB Logs confirm that external actors successfully authenticated and accessed the data, immediately notify the Data Protection Officer (DPO).

Under UK GDPR, the ICO (Information Commissioner's Office) must be notified within **72 hours** of discovering a breach of PII/financial data.
