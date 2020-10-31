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

resource "aws_iam_policy_attachment" "rds_monitoring" {
  name       = "${var.tags_owner}-${var.tags_env}-policy-attachment"
  roles      = [aws_iam_role.rds_monitoring.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
