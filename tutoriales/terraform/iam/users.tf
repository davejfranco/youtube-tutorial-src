#iam user daveops
resource "aws_iam_user" "daveops" {
  name = "daveops"
}

#IAM group admins with user daveops
resource "aws_iam_group" "admins" {
  name = "admins"
}

resource "aws_iam_group_membership" "admins" {
  name  = "admins"
  group = aws_iam_group.admins.name
  users = [aws_iam_user.daveops.name]
}

resource "aws_iam_policy" "group_access" {
  name        = "s3-admin"
  description = "Allows full access to s3"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_group_policy_attachment" "admins" {
  group      = aws_iam_group.admins.name
  policy_arn = aws_iam_policy.group_access.arn
}

resource "aws_iam_policy" "string_access" {
  name        = "string_access"
  description = "Admin role"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "route53:*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_group_policy_attachment" "string_access" {
  group      = aws_iam_group.admins.name
  policy_arn = aws_iam_policy.string_access.arn
}

#IAM role
resource "aws_iam_role" "admin_role" {
  name = "admin_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = aws_iam_group.admins.arn
        }
      },
    ]
  })
}


resource "aws_iam_policy" "role_access" {
  name        = "admin-role-access"
  description = "Admin role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "admin_role" {
  role       = aws_iam_role.admin_role.name
  policy_arn = aws_iam_policy.role_access.arn
}