# AssumeRole
resource "aws_iam_role" "lambda" {
  name = "${var.tags_owner}-${var.tags_env}-role-lambda"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

# Policy
resource "aws_iam_policy" "lambda_1" {
  name   = "${var.tags_owner}-${var.tags_env}-lambda-1"
  path   = "/"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
POLICY
}

# rds
resource "aws_iam_policy" "lambda_2" {
  name   = "${var.tags_owner}-${var.tags_env}-policy-lambda-2"
  path   = "/"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "rds:DescribeDBClusters",
                "rds:DescribeDBInstances",
                "rds:StopDBCluster",
                "rds:StopDBInstance"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}


# aws_iam_policy_attachment
resource "aws_iam_policy_attachment" "lambda_1" {
  name       = "lambda_1"
  roles      = [aws_iam_role.lambda.name]
  policy_arn = aws_iam_policy.lambda_1.arn
}

resource "aws_iam_policy_attachment" "lambda_2" {
  name       = "lambda_2"
  roles      = [aws_iam_role.lambda.name]
  policy_arn = aws_iam_policy.lambda_2.arn
}