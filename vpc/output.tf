output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "route_table_public" {
  value = aws_route_table.public.id
}

output "route_table_private" {
  value = data.aws_vpc.common_vpc.main_route_table_id
}