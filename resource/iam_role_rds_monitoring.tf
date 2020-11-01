# rds_monitoring_role
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.tags_owner}-${var.tags_env}-role-rds-monitoring"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "monitoring.rds.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-role-rds-monitoring"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# rds_monitoring
resource "aws_iam_policy" "rds_monitoring" {
  name = "${var.tags_owner}-${var.tags_env}-policy-rds-monitoring"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnableCreationAndManagementOfRDSCloudwatchLogGroups",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:PutRetentionPolicy"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:RDS*"
            ]
        },
        {
            "Sid": "EnableCreationAndManagementOfRDSCloudwatchLogStreams",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:GetLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:RDS*:log-stream:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "rds_monitoring" {
  name       = "${var.tags_owner}-${var.tags_env}-policy-attachment"
  roles      = [aws_iam_role.rds_monitoring.name]
  policy_arn = aws_iam_policy.rds_monitoring.arn
}