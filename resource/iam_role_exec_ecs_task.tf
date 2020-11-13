# [参考]
# https://github.com/turnerlabs/terraform-ecs-fargate-scheduled-task/blob/master/env/dev/ecs.tf
#
# ecsTaskExecutionRole:   AssumeRole = ecs-tasks.amazonaws.com
#                         policy     = ecr,logs,secretsmanager,kms
# cloudwatch_events_role: AssumeRole = events.amazonaws.com
#                         policy     = ecs:RunTask to ecs-task
#                         passrole   = ec2_role,ecsTaskExecutionRole
#
#

# ecsTaskExecutionRole
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.tags_owner}-${var.tags_env}-role-ecs"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# allow task execution role to worl with secret manager
resource "aws_iam_policy" "exec_task_1" {
  name   = "${var.tags_owner}-${var.tags_env}-policy-exec-task-1"
  path   = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "secretsmanager:GetSecretValue",
                "kms:Decrypt"
            ],
            "Resource": "*"
        } 
    ]
}
EOF
}
resource "aws_iam_policy_attachment" "exec_task_1" {
  name       = "${var.tags_owner}-${var.tags_env}-exec-task-1"
  roles      = [aws_iam_role.ecsTaskExecutionRole.name]
  policy_arn = aws_iam_policy.exec_task_1.arn
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/CWE_IAM_role.html
resource "aws_iam_role" "cloudwatch_events_role" {
  name               = "${var.tags_owner}-${var.tags_env}-role-events"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "events.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# allow events role to run ecs tasks
resource "aws_iam_policy" "exec_task_2" {
  name   = "${var.tags_owner}-${var.tags_env}-policy-exec-task-2"
  path   = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:RunTask"
            ],
            "Resource": [
                "${aws_ecs_task_definition.logicalbackup_mypg_1.arn}",
                "${aws_ecs_task_definition.logicalbackup_mypg_2.arn}"
            ]
        } 
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "exec_task_2" {
  name       = "${var.tags_owner}-${var.tags_env}-exec-task-2"
  roles      = [aws_iam_role.cloudwatch_events_role.name]
  policy_arn = aws_iam_policy.exec_task_2.arn
}

# allow events role to pass role to task execution role and app role
resource "aws_iam_policy" "exec_task_3" {
  name   = "${var.tags_owner}-${var.tags_env}-policy-exec-task-3"
  path   = "/"
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
                "${aws_iam_role.ec2.arn}",
                "${aws_iam_role.ecsTaskExecutionRole.arn}"
            ],
            "Condition": {
                "StringLike": {
                    "iam:PassedToService": "ecs-tasks.amazonaws.com"
                }
            }
        } 
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "exec_task_3" {
  name       = "${var.tags_owner}-${var.tags_env}-exec-task-3"
  roles      = [aws_iam_role.cloudwatch_events_role.name]
  policy_arn = aws_iam_policy.exec_task_3.arn
}