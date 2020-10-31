# AssumeRole
resource "aws_iam_role" "redshift" {
  name = "${var.tags_owner}-${var.tags_env}-role-redshift"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "redshift.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-redshift-role"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# s3
resource "aws_iam_policy" "redshift_1" {
  name = "${var.tags_owner}-${var.tags_env}-policy-redshift-1"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
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

resource "aws_iam_policy_attachment" "redshift_1" {
  name       = "${var.tags_owner}-${var.tags_env}-policy-attachment"
  roles      = [aws_iam_role.redshift.name]
  policy_arn = aws_iam_policy.redshift_1.arn
}
