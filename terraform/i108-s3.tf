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