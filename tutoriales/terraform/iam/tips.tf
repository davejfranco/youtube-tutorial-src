#Tips
#Enforced https on a bucket
resource "aws_s3_bucket" "web" {
  bucket = "web.local"
}

resource "aws_s3_bucket_website_configuration" "web" {
  bucket = aws_s3_bucket.web.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}

data "aws_iam_policy_document" "web_secure" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      "${aws_s3_bucket.web.arn}/*",
    ]
    # Deny all request with TLS version less than 1.2
    # Refence: https://aws.amazon.com/blogs/storage/enforcing-encryption-in-transit-with-tls1-2-or-higher-with-amazon-s3/
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }

    # Deny all requests without TLS
    # Reference: https://repost.aws/knowledge-center/s3-bucket-policy-for-config-rule
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}