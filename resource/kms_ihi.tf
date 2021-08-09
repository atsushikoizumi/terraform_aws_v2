resource "aws_kms_key" "ihi" {
  description             = "IHI KMS Key"
  deletion_window_in_days = 7
  key_usage = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  is_enabled = true
  enable_key_rotation = true
  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Id": "key-consolepolicy-ihi",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.aws_account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access for Key Administrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.aws_account_id}:user/${var.aws_account_user}"
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_kms_alias" "ihi" {
  name          = "alias/${var.tags_owner}-${var.tags_env}-ihi"
  target_key_id = aws_kms_key.ihi.key_id
}