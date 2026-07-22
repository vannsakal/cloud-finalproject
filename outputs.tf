###########################
########### VPC ###########
###########################

output "private_subnet_a_id" {

  value       = aws_subnet.private_subnet_a.id
  description = "The ID of private Subnet A"

}

output "private_subnet_a_az" {

  value       = aws_subnet.private_subnet_a.availability_zone
  description = "The Availability Zone of Private Subnet A"

}

output "private_subnet_b_id" {

  value       = aws_subnet.private_subnet_b.id
  description = "The ID of private Subnet B"

}

output "private_subnet_b_az" {

  value       = aws_subnet.private_subnet_b.availability_zone
  description = "The Availability Zone of Private Subnet B"

}

output "public_subnet_a_id" {

  value       = aws_subnet.public_subnet_a.id
  description = "The ID of public Subnet A"

}

output "public_subnet_a_az" {

  value       = aws_subnet.public_subnet_a.availability_zone
  description = "The Availability Zone of Public Subnet A"

}

output "public_rt" {

  value       = aws_route_table.public_rt.id
  description = "The ID of the Public Route Table"

}

output "private_rt_a" {

  value       = aws_route_table.private_rt_a.id
  description = "The ID of the Private Route A table"

}

output "private_rt_b" {

  value       = aws_route_table.private_rt_b.id
  description = "The ID of the Private Route B table"

}

output "asg_id" {

  value       = aws_security_group.asg_sg.id
  description = "The ID of the ASG group"

}

output "alb_id" {

  value       = aws_security_group.alb_sg.id
  description = "The ID of the ALB group"

}


###########################
######## S3 BUCKET ########
###########################

output "s3_bucket_name" {
  value       = aws_s3_bucket.secure_bucket.id
  description = "The name of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.secure_bucket.arn
  description = "The ARN of the S3 bucket"
}

###########################
########### RDS ###########
###########################

output "rds_endpoint" {
  value       = aws_db_instance.app_db.address
  description = "The connection endpoint of the RDS instance"
}

output "db_secret_arn" {
  value       = aws_secretsmanager_secret.db_secret.arn
  description = "ARN of the Secrets Manager secret holding DB credentials"
}

###########################
######### ALB / APP #######
###########################

output "app_url" {
  value       = "http://${aws_lb.web_alb.dns_name}"
  description = "Public URL of the deployed web application"
}

###########################
####### CLOUDWATCH #########
###########################

output "cloudwatch_dashboard_url" {
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
  description = "Direct link to the CloudWatch dashboard"
}
