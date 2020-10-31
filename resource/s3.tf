# logs
resource "aws_s3_bucket" "logs" {
  bucket = "${var.tags_owner}-${var.tags_env}-logs"
  acl    = "private"

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "${var.tags_owner}-${var.tags_env}-data"
  acl    = "private"

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# redshift
resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Put bucket policy needed for audit logging",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::729911121831:user/logs"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-logs/*"
    },
    {
      "Sid": "Get bucket policy needed for audit logging ",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::729911121831:user/logs"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-logs"
    }
  ]
}  
EOF
}