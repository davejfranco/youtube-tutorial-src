/*
data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "ec2:Describe*",
    ]

    effect = "Allow"

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "test_policy"
  path        = "/"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "policy2" {
  name        = "test_policy2"
  path        = "/"
  description = "My test policy 2"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = data.aws_iam_policy_document.policy.json
}

data "aws_iam_policy_document" "source" {
  statement {
    sid       = "SourcePlaceholder"
    actions   = ["ec2:DescribeAccountAttributes"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "override" {
  statement {
    sid       = "OverridePlaceholder"
    actions   = ["s3:GetObject"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "politik" {
  source_policy_documents   = [data.aws_iam_policy_document.source.json]
  override_policy_documents = [data.aws_iam_policy_document.override.json]
}

resource "aws_iam_policy" "policy3" {
  name        = "test_policy2"
  path        = "/"
  description = "My test policy 3"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = data.aws_iam_policy_document.politik.json
}

data "aws_iam_policy_document" "merged" {
  source_policy_documents   = concat(
    [data.aws_iam_policy_document.source.json],
    [data.aws_iam_policy_document.override.json]
  )
}

resource "aws_iam_policy" "policy4" {
  name        = "test_policy2"
  path        = "/"
  description = "My test policy 4"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = data.aws_iam_policy_document.merged.json
}*/