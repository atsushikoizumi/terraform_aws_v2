# AssumeRole
resource "aws_iam_role" "ec2" {
  name = "${var.tags_owner}-${var.tags_env}-role-ec2"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com",
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-role-ec2"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# s3
resource "aws_iam_policy" "ec2_1" {
  name = "${var.tags_owner}-${var.tags_env}-policy-ec2-1"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:DeleteObject",
                "S3:GetBucketAcl",
                "s3:GetObject",
                "s3:ListAllMyBuckets",
                "s3:ListBucket",
                "s3:ListObjectsV2",
                "s3:PutObject"
            ],
            "Resource": [
              "arn:aws:s3:::aws-aqua-terraform",
              "arn:aws:s3:::aws-aqua-terraform/koizumi/windows/*",
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

# rds
resource "aws_iam_policy" "ec2_2" {
  name = "${var.tags_owner}-${var.tags_env}-policy-ec2-2"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "rds:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

/*
resource "aws_iam_policy" "ec2_2" {
  name = "${var.tags_owner}-${var.tags_env}-policy-ec2-2"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "rds:DescribeDBInstances"
            ],
            "Resource": "arn:aws:rds:eu-north-1:532973931974:db:koizumi-dev-db-oracle-1st"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:ListAttachedRolePolicies"
            ],
            "Resource": [
              "arn:aws:iam::532973931974:role/koizumi-dev-role-rds"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetPolicy",
                "iam:GetPolicyVersion"
            ],
            "Resource": [
              "arn:aws:iam::532973931974:policy/koizumi-dev-policy-rds-1"
            ]
        }
    ]
}
EOF
}
*/

# clodwatch logs
resource "aws_iam_policy" "ec2_3" {
  name = "${var.tags_owner}-${var.tags_env}-policy-ec2-3"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:GetLogEvents",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# ec2
resource "aws_iam_policy" "ec2_4" {
  name = "${var.tags_owner}-${var.tags_env}-policy-ec2-4"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# ecr
resource "aws_iam_policy" "ec2_5" {
  name = "${var.tags_owner}-${var.tags_env}-policy-ec2-5"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Action": [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:DescribeImages",
            "ecr:BatchGetImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage"
        ],
        "Resource": "*"
    }]
}
EOF
}

# ecr
resource "aws_iam_policy" "ec2_6" {
  name = "${var.tags_owner}-${var.tags_env}-policy-ec2-6"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "redshift:*"
            ],
            "Resource": "*"
        } 
    ]
}
EOF
}

# ecr
resource "aws_iam_policy" "ec2_7" {
  name = "${var.tags_owner}-${var.tags_env}-policy-ec2-7"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "kms:Decrypt"
            ],
            "Resource": "*"
        } 
    ]
}
EOF
}

# PassRole
resource "aws_iam_policy" "ec2_8" {
  name = "${var.tags_owner}-${var.tags_env}-policy-ec2-8"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": [
                "${aws_iam_role.rds.arn}",
                "${aws_iam_role.rds_monitoring.arn}"
            ],
            "Condition": {
                "StringLike": {
                    "iam:PassedToService": "rds.amazonaws.com"
                }
            }
        } 
    ]
}
EOF
}

# PassRolearn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
resource "aws_iam_policy" "ec2_9" {
  name = "${var.tags_owner}-${var.tags_env}-policy-ec2-9"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:DescribeDocument",
                "ssm:GetManifest",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess
resource "aws_iam_policy" "ec2_10" {
  name = "${var.tags_owner}-${var.tags_env}-policy-ec2-10"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ds:CreateComputer",
                "ds:DescribeDirectories"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


# aws_iam_policy_attachment
resource "aws_iam_policy_attachment" "ec2_1" {
  name       = "ec2_1"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = aws_iam_policy.ec2_1.arn
}

resource "aws_iam_policy_attachment" "ec2_2" {
  name       = "ec2_2"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = aws_iam_policy.ec2_2.arn
}

resource "aws_iam_policy_attachment" "ec2_3" {
  name       = "ec2_3"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = aws_iam_policy.ec2_3.arn
}

resource "aws_iam_policy_attachment" "ec2_4" {
  name       = "ec2_4"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = aws_iam_policy.ec2_4.arn
}

resource "aws_iam_policy_attachment" "ec2_5" {
  name       = "ec2_5"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = aws_iam_policy.ec2_5.arn
}

resource "aws_iam_policy_attachment" "ec2_6" {
  name       = "ec2_6"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = aws_iam_policy.ec2_6.arn
}

resource "aws_iam_policy_attachment" "ec2_7" {
  name       = "ec2_7"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = aws_iam_policy.ec2_7.arn
}

resource "aws_iam_policy_attachment" "ec2_8" {
  name       = "ec2_8"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = aws_iam_policy.ec2_8.arn
}

resource "aws_iam_policy_attachment" "ec2_9" {
  name       = "ec2_9"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = aws_iam_policy.ec2_9.arn
}

resource "aws_iam_policy_attachment" "ec2_10" {
  name       = "ec2_10"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = aws_iam_policy.ec2_10.arn
}
