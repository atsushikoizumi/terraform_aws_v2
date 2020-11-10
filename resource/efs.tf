# logicalbackup
resource "aws_efs_file_system" "logicalbackup" {
  creation_token = "${var.tags_owner}-${var.tags_env}-logicalbackup"

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}

# msut be 1 az 1 mount target
resource "aws_efs_mount_target" "logicalbackup" {
  for_each        = var.ec2_subnet
  file_system_id  = aws_efs_file_system.logicalbackup.id
  subnet_id       = aws_subnet.ec2[each.key].id
  security_groups = [aws_security_group.ec2.id]
}