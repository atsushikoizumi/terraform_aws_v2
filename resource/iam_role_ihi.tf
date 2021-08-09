#
# RDS Role for IHI
#
resource "aws_iam_role" "rds_ihi" {
  name = "${var.tags_owner}-${var.tags_env}-rds-ihi"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-rds-ihi"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

resource "aws_iam_policy" "rds_ihi" {
  name = "${var.tags_owner}-${var.tags_env}-policy-rds-ihi"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
	      {
	          "Effect": "Allow",
	          "Action": "s3:ListAllMyBuckets",
	          "Resource": "*"
	      },
        {
            "Sid": "s3export",
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "S3:GetBucketAcl",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:GetObjectMetaData",
                "s3:ListBucket",
                "s3:ListMultipartUploadParts",
                "s3:PutObject"
            ],
            "Resource": [
              "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-ihi",
              "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-ihi/*"
            ]
        },
        {
            "Sid": "KMSActions",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:Encrypt",
                "kms:ReEncrypt",
                "kms:GenerateDataKey",
                "kms:DescribeKey"
            ],
            "Resource": "${aws_kms_key.ihi.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "rds_ihi" {
  name       = "${var.tags_owner}-${var.tags_env}-rds-ihi-1"
  roles      = [aws_iam_role.rds2.name]
  policy_arn = aws_iam_policy.rds_2.arn
}

