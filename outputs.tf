###########################
########### VPC ###########
###########################

output "private_subnet_a_id" {

  value = aws_subnet.private_subnet_a.id
  description = "The ID of private Subnet A"

}

output "private_subnet_a_az" {

  value = aws_subnet.private_subnet_a.availability_zone
  description = "The Availability Zone of Private Subnet A"
  
}

output "private_subnet_b_id" {

  value = aws_subnet.private_subnet_b.id
  description = "The ID of private Subnet B"

}

output "private_subnet_b_az" {

  value = aws_subnet.private_subnet_b.availability_zone
  description = "The Availability Zone of Private Subnet B"
  
}

output "public_subnet_a_id" {
  
  value = aws_subnet.public_subnet_a.id
  description = "The ID of public Subnet A"

}

output "public_subnet_a_az" {
  
  value = aws_subnet.public_subnet_a.availability_zone
  description = "The Availability Zone of Public Subnet A"

}

output "public_rt" {

  value = aws_route_table.public_rt.id
  description = "The ID of the Public Route Table"
  
}

output "private_rt" {
  
  value = aws_route_table.private_rt.id
  description = "The ID of the Private Route table"

}

output "cloud_project_group_id" {

  value = aws_security_group.cloud_project_group.id
  description = "The ID of the cloud project group"
  
}

###########################
########### EC2 ###########
###########################

# value of public DNS 

output "web_server_public_dns" {
  value = aws_instance.WebServer.public_dns
}

# value of public IP

output "web_server_public_ip" {
  value = aws_instance.WebServer.public_ip
}

output "website_url" {
  
  value = "http://${aws_instance.WebServer.public_dns}"
  description = "The URL to access the web server"

}