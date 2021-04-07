# logicalbackup for aurora postgresql
resource "aws_ecs_task_definition" "logicalbackup_mypg_1" {
  family                   = "${aws_rds_cluster.aurora_postgre_1st.cluster_identifier}-xx00"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ec2.arn

  container_definitions = <<TASK_DEFINITION
[
    {
        "name": "${aws_rds_cluster.aurora_postgre_1st.cluster_identifier}-xx00",
        "image": "${aws_ecr_repository.logicalbackup_mypg.repository_url}:ver1.5",
        "cpu": 0,
        "memoryReservation": 128,
        "command": [],
        "entryPoint": [],
        "portMappings": [],
        "volumesFrom": [],
        "environment": [
            {"name": "tags_owner", "value": "${var.tags_owner}"},
            {"name": "tags_env", "value": "${var.tags_env}"},
            {"name": "DB_CLUSTER_IDENTIFIER", "value": "${aws_rds_cluster.aurora_postgre_1st.cluster_identifier}"},
            {"name": "DB_NAME", "value": "xx00"},
            {"name": "DB_MASTER", "value": "${aws_rds_cluster.aurora_postgre_1st.master_username}"},
            {"name": "PASSWORD_KEY", "value": "postgresql"},
            {"name": "DB_INSTANCE_CLASS", "value": "db.t3.medium"},
            {"name": "DB_SUBNET_GROUP", "value": "${aws_db_subnet_group.rds.name}"},
            {"name": "DB_PORT", "value": "${aws_rds_cluster.aurora_postgre_1st.port}"},
            {"name": "VPC_SECURITY_GROUP_IDS", "value": "${aws_security_group.rds.id}"},
            {"name": "S3_BUCKET", "value": "${aws_s3_bucket.data.bucket}"},
            {"name": "S3_PREFIX", "value": "backup/rds/postgresql"}
        ],
        "secrets": [
          {
            "name": "${aws_secretsmanager_secret.dbpassword.name}",
            "valueFrom": "${aws_secretsmanager_secret.dbpassword.arn}"
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
                "containerPath": "/root/efs",
                "sourceVolume": "${var.tags_owner}-${var.tags_env}-logicalbackup"
            } 
        ]
    }
]
TASK_DEFINITION

  # fargate で efs を利用するときは、タスク実行時の Platform version を1.4以上に指定しなければいけない。
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


# logicalbackup for aurora mysql
resource "aws_ecs_task_definition" "logicalbackup_mypg_2" {
  family                   = "${aws_rds_cluster.aurora_mysql_1st.cluster_identifier}-xx00"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ec2.arn

  container_definitions = <<TASK_DEFINITION
[
    {
        "name": "${aws_rds_cluster.aurora_mysql_1st.cluster_identifier}-xx00",
        "image": "${aws_ecr_repository.logicalbackup_mypg.repository_url}:ver1.5",
        "cpu": 0,
        "memoryReservation": 128,
        "command": [],
        "entryPoint": [],
        "portMappings": [],
        "volumesFrom": [],
        "environment": [
            {"name": "tags_owner", "value": "${var.tags_owner}"},
            {"name": "tags_env", "value": "${var.tags_env}"},
            {"name": "DB_CLUSTER_IDENTIFIER", "value": "${aws_rds_cluster.aurora_mysql_1st.cluster_identifier}"},
            {"name": "DB_NAME", "value": "xx00"},
            {"name": "DB_MASTER", "value": "${aws_rds_cluster.aurora_mysql_1st.master_username}"},
            {"name": "PASSWORD_KEY", "value": "mysql"},
            {"name": "DB_INSTANCE_CLASS", "value": "db.t3.medium"},
            {"name": "DB_SUBNET_GROUP", "value": "${aws_db_subnet_group.rds.name}"},
            {"name": "DB_PORT", "value": "${aws_rds_cluster.aurora_mysql_1st.port}"},
            {"name": "VPC_SECURITY_GROUP_IDS", "value": "${aws_security_group.rds.id}"},
            {"name": "S3_BUCKET", "value": "${aws_s3_bucket.data.bucket}"},
            {"name": "S3_PREFIX", "value": "backup/rds/mysql"}
        ],
        "secrets": [
          {
            "name": "${aws_secretsmanager_secret.dbpassword.name}",
            "valueFrom": "${aws_secretsmanager_secret.dbpassword.arn}"
          }
        ],
        "essential": true,
        "logConfiguration": {
            "logDriver": "awslogs",
            "options" : {
                "awslogs-group": "/aws/fargate/${aws_rds_cluster.aurora_mysql_1st.cluster_identifier}",
                "awslogs-region": "eu-north-1",
                "awslogs-stream-prefix": "logicalbackup",
                "awslogs-create-group": "true"
            }
        },
        "mountPoints": [
            {
                "containerPath": "/root/efs",
                "sourceVolume": "${var.tags_owner}-${var.tags_env}-logicalbackup"
            } 
        ]
    }
]
TASK_DEFINITION

  # fargate で efs を利用するときは、タスク実行時の Platform version を1.4以上に指定しなければいけない。
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

# logicalbackup for aurora oracle
resource "aws_ecs_task_definition" "logicalbackup_orms_1" {
  family                   = "${aws_db_instance.oracle_1st.identifier}-XX_ADM"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ec2.arn

  container_definitions = <<TASK_DEFINITION
[
    {
        "name": "${aws_db_instance.oracle_1st.identifier}-XX_ADM",
        "image": "${aws_ecr_repository.logicalbackup_orms.repository_url}:ver1.0",
        "cpu": 0,
        "memoryReservation": 128,
        "command": [],
        "entryPoint": [],
        "portMappings": [],
        "volumesFrom": [],
        "environment": [
            {"name": "tags_owner", "value": "${var.tags_owner}"},
            {"name": "tags_env", "value": "${var.tags_env}"},
            {"name": "DB_INSTANCE_IDENTIFIER", "value": "${aws_db_instance.oracle_1st.identifier}"},
            {"name": "DB_NAME", "value": "MASTERDB"},
            {"name": "DB_SCHEMA", "value": "XX_ADM"},
            {"name": "DB_MASTER", "value": "${aws_db_instance.oracle_1st.username}"},
            {"name": "PASSWORD_KEY", "value": "oracle"},
            {"name": "DB_INSTANCE_CLASS", "value": "db.t3.medium"},
            {"name": "DB_SUBNET_GROUP", "value": "${aws_db_subnet_group.rds.name}"},
            {"name": "DB_PORT", "value": "${aws_db_instance.oracle_1st.port}"},
            {"name": "VPC_SECURITY_GROUP_IDS", "value": "${aws_security_group.rds.id}"},
            {"name": "S3_BUCKET", "value": "${aws_s3_bucket.data.bucket}"},
            {"name": "S3_PREFIX", "value": "backup/rds/oracle"},
            {"name": "S3_INTEGRATION", "value": "${aws_iam_role.rds.arn}"}
        ],
        "secrets": [
          {
            "name": "${aws_secretsmanager_secret.dbpassword.name}",
            "valueFrom": "${aws_secretsmanager_secret.dbpassword.arn}"
          }
        ],
        "essential": true,
        "logConfiguration": {
            "logDriver": "awslogs",
            "options" : {
                "awslogs-group": "/aws/fargate/${aws_db_instance.oracle_1st.identifier}",
                "awslogs-region": "eu-north-1",
                "awslogs-stream-prefix": "logicalbackup",
                "awslogs-create-group": "true"
            }
        },
        "mountPoints": [
            {
                "containerPath": "/root/efs",
                "sourceVolume": "${var.tags_owner}-${var.tags_env}-logicalbackup"
            } 
        ]
    }
]
TASK_DEFINITION

  # fargate で efs を利用するときは、タスク実行時の Platform version を1.4以上に指定しなければいけない。
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

# logicalbackup for aurora sqlserver
resource "aws_ecs_task_definition" "logicalbackup_orms_2" {
  family                   = "${aws_db_instance.sqlserver_1st.identifier}-xx00"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ec2.arn

  container_definitions = <<TASK_DEFINITION
[
    {
        "name": "${aws_db_instance.sqlserver_1st.identifier}-xx00",
        "image": "${aws_ecr_repository.logicalbackup_orms.repository_url}:ver1.0",
        "cpu": 0,
        "memoryReservation": 128,
        "command": [],
        "entryPoint": [],
        "portMappings": [],
        "volumesFrom": [],
        "environment": [
            {"name": "tags_owner", "value": "${var.tags_owner}"},
            {"name": "tags_env", "value": "${var.tags_env}"},
            {"name": "DB_INSTANCE_IDENTIFIER", "value": "${aws_db_instance.sqlserver_1st.identifier}"},
            {"name": "DB_NAME", "value": "xx00"},
            {"name": "DB_MASTER", "value": "${aws_db_instance.sqlserver_1st.username}"},
            {"name": "PASSWORD_KEY", "value": "sqlserver"},
            {"name": "DB_INSTANCE_CLASS", "value": "db.r5.large"},
            {"name": "DB_SUBNET_GROUP", "value": "${aws_db_subnet_group.rds.name}"},
            {"name": "DB_PORT", "value": "${aws_db_instance.sqlserver_1st.port}"},
            {"name": "VPC_SECURITY_GROUP_IDS", "value": "${aws_security_group.rds.id}"},
            {"name": "S3_BUCKET", "value": "${aws_s3_bucket.data.bucket}"},
            {"name": "S3_PREFIX", "value": "backup/rds/sqlserver"}
        ],
        "secrets": [
          {
            "name": "${aws_secretsmanager_secret.dbpassword.name}",
            "valueFrom": "${aws_secretsmanager_secret.dbpassword.arn}"
          }
        ],
        "essential": true,
        "logConfiguration": {
            "logDriver": "awslogs",
            "options" : {
                "awslogs-group": "/aws/fargate/${aws_db_instance.sqlserver_1st.identifier}",
                "awslogs-region": "eu-north-1",
                "awslogs-stream-prefix": "logicalbackup",
                "awslogs-create-group": "true"
            }
        },
        "mountPoints": [
            {
                "containerPath": "/root/efs",
                "sourceVolume": "${var.tags_owner}-${var.tags_env}-logicalbackup"
            } 
        ]
    }
]
TASK_DEFINITION

  # fargate で efs を利用するときは、タスク実行時の Platform version を1.4以上に指定しなければいけない。
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
