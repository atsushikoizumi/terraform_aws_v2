# aws_key_pair
# https://www.terraform.io/docs/providers/aws/r/key_pair.html
# https://www.terraform.io/docs/providers/tls/r/private_key.html
resource "aws_key_pair" "key_pair" {
  key_name   = "${var.tags_owner}-${var.tags_env}-key-pair"
  public_key = file(var.public_key_path)

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}