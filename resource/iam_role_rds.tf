# AssumeRole
resource "aws_iam_role" "rds" {
  name = "${var.tags_owner}-${var.tags_env}-role-rds"

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
    Name  = "${var.tags_owner}-${var.tags_env}-role-rds"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# s3
resource "aws_iam_policy" "rds_1" {
  name = "${var.tags_owner}-${var.tags_env}-policy-rds-1"
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
            "Sid": "s3import",
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
              "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-logs",
              "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-logs/*",
              "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-data",
              "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-data/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "rds_1" {
  name       = "${var.tags_owner}-${var.tags_env}-policy-attachment"
  roles      = [aws_iam_role.rds.name]
  policy_arn = aws_iam_policy.rds_1.arn
}


# AssumeRole
resource "aws_iam_role" "rds2" {
  name = "${var.tags_owner}-${var.tags_env}-role-rds2"

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
    Name  = "${var.tags_owner}-${var.tags_env}-role-rds2"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# s3
resource "aws_iam_policy" "rds_2" {
  name = "${var.tags_owner}-${var.tags_env}-policy-rds-2"
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
              "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-logs",
              "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-logs/*",
              "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-data",
              "arn:aws:s3:::${var.tags_owner}-${var.tags_env}-data/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "rds_2" {
  name       = "${var.tags_owner}-${var.tags_env}-policy-attachment2"
  roles      = [aws_iam_role.rds2.name]
  policy_arn = aws_iam_policy.rds_2.arn
}