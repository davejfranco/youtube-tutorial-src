#S3 bucket
resource "aws_s3_bucket" "store" {
  bucket = "store.local"
  acl    = "private"

  tags = {
    Name        = "store"
    Environment = "local"
  }
}



data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [
        aws_iam_group.admins.arn,
      ]
    }
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.store.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "store" {
  bucket = aws_s3_bucket.store.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}