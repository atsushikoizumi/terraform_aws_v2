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
                "s3:ListAllMyBuckets",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "S3:GetBucketAcl"
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
                "rds:CreateDBCluster",
                "rds:CreateDBClusterParameterGroup",
                "rds:CreateDBInstance",
                "rds:CreateDBInstanceReadReplica",
                "rds:CreateDBParameterGroup",
                "rds:CreateDBSubnetGroup",
                "rds:DeleteDBCluster",
                "rds:DeleteDBClusterSnapshot",
                "rds:DeleteDBInstance",
                "rds:DescribeDBClusterParameterGroups",
                "rds:DescribeDBClusterParameters",
                "rds:DescribeDBClusters",
                "rds:DescribeDBClusterSnapshots",
                "rds:DescribeDBInstances",
                "rds:DescribeOptionGroups",
                "rds:DescribeDBParameterGroups",
                "rds:DescribeDBParameters",
                "rds:ModifyDBClusterParameterGroup",
                "rds:ModifyDBParameterGroup",
                "rds:StartDBCluster",
                "rds:StartDBInstance",
                "rds:StopDBCluster",
                "rds:StopDBInstance",
                "rds:RebootDBInstance",
                "rds:RestoreDBClusterFromSnapshot"
            ],
            "Resource": "arn:aws:rds:::${var.tags_owner}-${var.tags_env}-*"
        }
    ]
}
EOF
}

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
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:GetLogEvents",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:::${var.tags_owner}-${var.tags_env}-*"
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
                "ec2:DescribeImages"
            ],
            "Resource": "arn:aws:ecr:::repository/${var.tags_owner}-${var.tags_env}-*"
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
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage"
            ],
            "Resource": "arn:aws:ecr:::repository/${var.tags_owner}-${var.tags_env}-*"
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