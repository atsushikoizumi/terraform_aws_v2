output "ec2_amzn2" {
  value = aws_instance.ec2_amzn2.public_ip
}

output "ec2_win2019" {
  value = aws_instance.ec2_win2019.public_ip
}
/*
output "aurora_mysql_1st_ep" {
  value = aws_rds_cluster.aurora_mysql_1st.endpoint
}

output "aurora_mysql_1st_pt" {
  value = aws_rds_cluster.aurora_mysql_1st.port
}

output "aurora_mysql_1st_db" {
  value = aws_rds_cluster.aurora_mysql_1st.database_name
}

output "aurora_mysql_1st_mu" {
  value = aws_rds_cluster.aurora_mysql_1st.master_username
}

output "aurora_postgre_1st_ep" {
  value = aws_rds_cluster.aurora_postgre_1st.endpoint
}

output "aurora_postgre_1st_pt" {
  value = aws_rds_cluster.aurora_postgre_1st.port
}

output "aurora_postgre_1st_db" {
  value = aws_rds_cluster.aurora_postgre_1st.database_name
}

output "aurora_postgre_1st_mu" {
  value = aws_rds_cluster.aurora_postgre_1st.master_username
}

output "oracle_1st_ep" {
  value = aws_db_instance.oracle_1st.endpoint
}

output "oracle_1st_db" {
  value = aws_db_instance.oracle_1st.name
}

output "oracle_1st_mu" {
  value = aws_db_instance.oracle_1st.username
}

output "sqlserver_1st_ep" {
  value = aws_db_instance.sqlserver_1st.endpoint
}

output "sqlserver_1st_mu" {
  value = aws_db_instance.sqlserver_1st.username
}

output "redshift_1st_ep" {
  value = aws_redshift_cluster.redshift_1st.endpoint
}

output "redshift_1st_db" {
  value = aws_redshift_cluster.redshift_1st.database_name
}

output "redshift_1st_mu" {
  value = aws_redshift_cluster.redshift_1st.master_username
}
*/
