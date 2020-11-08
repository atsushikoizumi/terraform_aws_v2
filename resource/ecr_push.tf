# push repository
resource "null_resource" "push_image_1" {
  triggers = {
    endpoint   = aws_instance.ec2_amzn2.public_dns
    repository = aws_ecr_repository.repository_1.repository_url
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.ec2_amzn2.public_dns
      user        = "ec2-user"
      private_key = file(var.private_key_path)
    }

    inline = [
      "touch ~/test.txt",
      "date >> ~/test.txt"
    ]
  }
}

