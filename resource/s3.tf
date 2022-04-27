# logs
resource "aws_s3_bucket" "logs" {
  bucket = "${var.tags_owner}-${var.tags_env}-logs"

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# data
resource "aws_s3_bucket" "data" {
  bucket = "${var.tags_owner}-${var.tags_env}-data"

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# kms
resource "aws_s3_bucket" "kms" {
  bucket = "${var.tags_owner}-${var.tags_env}-kms"

/*  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3key.arn
        sse_algorithm     = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }
*/
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "kms" {
  bucket = aws_s3_bucket.kms.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3key.arn
      sse_algorithm     = "aws:kms"
    }
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