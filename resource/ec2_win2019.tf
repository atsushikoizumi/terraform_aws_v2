# search ami
# https://dev.classmethod.jp/articles/launch-ec2-from-latest-ami-by-terraform/
data "aws_ami" "win2019_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["Windows_Server-2019-Japanese-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }
}

# EC2
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "win2019_1" {
  ami           = data.aws_ami.win2019_ami.id
  instance_type = "t3.xlarge"
  key_name      = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]
  subnet_id = aws_subnet.ec2["eu-north-1a"].id
  root_block_device {
    volume_type = "gp2"
    volume_size = "30"
  }
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-win2019"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}