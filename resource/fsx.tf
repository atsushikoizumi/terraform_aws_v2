# Fsx for Database
resource "aws_fsx_windows_file_system" "allwayson" {
  active_directory_id = aws_directory_service_directory.main.id
  storage_capacity    = 100
  subnet_ids          = [aws_subnet.ec2["eu-north-1a"].id,aws_subnet.ec2["eu-north-1b"].id]
  throughput_capacity = 16
  deployment_type     = "MULTI_AZ_1"
  security_group_ids  = [aws_security_group.ec2.id]
  preferred_subnet_id = aws_subnet.ec2["eu-north-1a"].id
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-fsx"
    Owner = var.tags_owner
    Env   = var.tags_env
  }

}

# Fsx for Quorum
resource "aws_fsx_windows_file_system" "quorum" {
  active_directory_id = aws_directory_service_directory.main.id
  storage_capacity    = 100
  subnet_ids          = [aws_subnet.ec2["eu-north-1c"].id]
  throughput_capacity = 16
  deployment_type     = "SINGLE_AZ_1"
  security_group_ids  = [aws_security_group.ec2.id]
  tags = {
    Name  = "${var.tags_owner}-${var.tags_env}-fsx2"
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}