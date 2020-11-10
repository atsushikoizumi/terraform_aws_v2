resource "aws_ecs_task_definition" "logicalbackup" {
  family                   = aws_rds_cluster.aurora_postgre_1st.cluster_identifier
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ec2.arn
  task_role_arn            = aws_iam_role.ec2.arn

  container_definitions = <<TASK_DEFINITION
[
    {
        "name": "${aws_rds_cluster.aurora_postgre_1st.cluster_identifier}",
        "image": "${aws_ecr_repository.logicalbackup.repository_url}:ver1.2",
        "cpu": 0,
        "memoryReservation": 128,
        "command": [],
        "entryPoint": [],
        "portMappings": [],
        "volumesFrom": [],
        "environment": [
            {"name": "DB_CLUSTER_IDENTIFIER", "value": "${aws_rds_cluster.aurora_postgre_1st.cluster_identifier}"},
            {"name": "DB_NAME", "value": "xx00"},
            {"name": "DB_OWNER", "value": "xx_adm"},
            {"name": "DB_INSTANCE_CLASS", "value": "db.t3.medium"},
            {"name": "DB_SUBNET_GROUP", "value": "${aws_db_subnet_group.rds.name}"},
            {"name": "DB_PORT", "value": "${aws_rds_cluster.aurora_postgre_1st.port}"},
            {"name": "VPC_SECURITY_GROUP_IDS", "value": "${aws_security_group.rds.id}"},
            {"name": "S3_BUCKET", "value": "${aws_s3_bucket.data.bucket}"},
            {"name": "S3_PREFIX", "value": "backup/rds/postgresql"}
        ],
        "secrets": [
          {
            "name": "${aws_secretsmanager_secret.aurora_pass.name}",
            "valueFrom": "${aws_secretsmanager_secret.aurora_pass.arn}"
          }
        ],
        "essential": true,
        "logConfiguration": {
            "logDriver": "awslogs",
            "options" : {
                "awslogs-group": "/aws/fargate/${aws_rds_cluster.aurora_postgre_1st.cluster_identifier}",
                "awslogs-region": "eu-north-1",
                "awslogs-stream-prefix": "logicalbackup",
                "awslogs-create-group": "true"
            }
        },
        "mountPoints": [
            {
                "containerPath": "/root/logs",
                "sourceVolume": "${var.tags_owner}-${var.tags_env}-logicalbackup"
            } 
        ]
    }
]
TASK_DEFINITION

  volume {
    name = "${var.tags_owner}-${var.tags_env}-logicalbackup"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.logicalbackup.id
      root_directory     = "/"
      transit_encryption = "DISABLED"
      #transit_encryption_port = 0
      authorization_config {
        access_point_id = ""
        iam             = "DISABLED"
      }
    }
  }

  tags = {
    Owner = var.tags_owner
    Env   = var.tags_env
  }
}