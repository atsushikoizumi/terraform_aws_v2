output "ec2_amzn2" {
  value = aws_instance.ec2_amzn2.public_ip
}

output "ec2_win2019" {
  value = aws_instance.ec2_win2019.public_ip
}

output "aurora_mysql_1st_ep" {
  value = aws_rds_cluster.aurora_mysql_1st.endpoint
}

output "aurora_mysql_1st_pt" {
  value = aws_rds_cluster.aurora_mysql_1st.port
}

output "aurora_postgre_1st_ep" {
  value = aws_rds_cluster.aurora_postgre_1st.endpoint
}

output "aurora_postgre_1st_pt" {
  value = aws_rds_cluster.aurora_postgre_1st.port
}

output "oracle_1st" {
  value = aws_db_instance.oracle_1st.endpoint
}

output "sqlserver_1st" {
  value = aws_db_instance.sqlserver_1st.endpoint
}

output "redshift_1st" {
  value = aws_redshift_cluster.redshift_1st.endpoint
}

