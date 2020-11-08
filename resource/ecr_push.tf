# push repository
resource "null_resource" "push_image_1" {
  triggers = {
    endpoint   = aws_instance.ec2_amzn2.public_dns
    repository = aws_ecr_repository.repository_1.repository_url
    source_code_hash = filebase64sha256("../../build/docker/logical_backup.tar.gz")
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      host        = aws_instance.ec2_amzn2.public_dns
      user        = "ec2-user"
      private_key = file(var.private_key_path)
    }
    source      = "../../build/docker/logical_backup.tar.gz"
    destination = "/tmp/logical_backup.tar.gz"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.ec2_amzn2.public_dns
      user        = "ec2-user"
      private_key = file(var.private_key_path)
    }
    inline = [
      "date >> ~/docker.log",
      "cp /tmp/logical_backup.tar.gz ./",
      "tar -zxvf logical_backup.tar.gz",
      "docker build -t logical_backup:latest ./logical_backup",
      "docker image ls >> ~/docker.log",
      "aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 933432669293.dkr.ecr.ap-northeast-1.amazonaws.com",
      "docker tag sefrom30com/amzn2:20201026 933432669293.dkr.ecr.ap-northeast-1.amazonaws.com/aqua-koizumi-sshd:20201026",
      "docker push 933432669293.dkr.ecr.ap-northeast-1.amazonaws.com/aqua-koizumi-sshd:20201026"
    ]
  }
}

