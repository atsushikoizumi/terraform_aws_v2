# s3 for IHI
resource "aws_s3_bucket" "ihi" {
  bucket = "${var.tags_owner}-${var.tags_env}-ihi"
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.ihi.arn
        sse_algorithm     = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}