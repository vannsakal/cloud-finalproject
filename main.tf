# Create the VPC (isolated private network in aws)

resource "aws_vpc" "main" {

    cidr_block = var.main_vpc_cidr
    instance_tenancy = "default"
    enable_dns_hostnames = true
    tags = {

        "Name" = "tf-vpc-project"

    }

}

# Create Internet Gateway and attach it to VPC

resource "aws_internet_gateway" "igw" { 
    
    vpc_id = aws_vpc.main.id
    tags = {
        "Name" = "tf-igw-project"
    }
}

# Create 3 subnets: two private and one public

resource "aws_subnet" "public_subnet_a" {
  
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_range_a
  map_public_ip_on_launch = true    # any instances launched in this subnet automatically gets a public IP address
  availability_zone = "ap-southeast-1a"
  tags = {
    "Name" = "${var.environment}-public-subnet-a"
  }

}

resource "aws_subnet" "private_subnet_a" {
  
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_range_a
  map_public_ip_on_launch = false
  availability_zone = "ap-southeast-1a"
  tags = {
    "Name" = "${var.environment}-private-subnet-a"
  }
  
}

resource "aws_subnet" "private_subnet_b" {
  
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_range_b
  map_public_ip_on_launch = false
  availability_zone = "ap-southeast-1b"
  tags = {
    "Name" = "${var.environment}-private-subnet-b"
  }
  
}

# Create Route table for Private Subnets

resource "aws_route_table" "private_rt" {
  
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${var.environment}-private-route-table"
  }

}

# Create Route table for Public Subnets

resource "aws_route_table" "public_rt" {
  
 vpc_id = aws_vpc.main.id
 route{

    # Traffic from Public Subnet reaches Internet via Internet Gateway
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
 }
 tags = {
   "Name" = "${var.environment}-public-route-table"
 }

}

# Route table Association with Private Subnet A

resource "aws_route_table_association" "private_rt_association_a" {
  
    subnet_id = aws_subnet.private_subnet_a.id
    route_table_id = aws_route_table.private_rt.id  # attach the Private route table to the subnet to follow the rules

}

# Route table Association with Private Subnet B

resource "aws_route_table_association" "private_rt_association_b" {
  
    subnet_id = aws_subnet.private_subnet_b.id
    route_table_id = aws_route_table.private_rt.id  # attach the Private route table to the subnet to follow the rules

}

# Route table Association with Public Subnet A

resource "aws_route_table_association" "public_rt_association_a" {
  
   subnet_id = aws_subnet.public_subnet_a.id
   route_table_id = aws_route_table.public_rt.id

}

# Define security group

resource "aws_security_group" "cloud_project_group" {
  
   name = "${var.environment}-dingus-sg"
   description = "Default Security group to allow inbound/outbound from the VPC"
   vpc_id = aws_vpc.main.id
   depends_on = [ aws_vpc.main ]

}

# Allow inbound SSH for EC2 instances

resource "aws_security_group_rule" "allow_ssh_in" {
  
  description = "Allow SSH"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]    # change it to 0.0.0.0/0
  security_group_id = aws_security_group.cloud_project_group.id

}

# Allow inbound HTTP for EC2 instances

resource "aws_security_group_rule" "allow_http_in" {
  
  description = "Allow inbount HTTP traffic"
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cloud_project_group.id

}

# Allow all outbound traffic

resource "aws_security_group_rule" "allow_all_out" {
  
  description = "Allow outbound traffic"
  type = "egress"
  from_port = "0"
  to_port = "0"
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cloud_project_group.id
  
}

###########################
########### EC2 ###########
###########################

resource "aws_instance" "WebServer" {
  
  ami = "ami-02d23a03f80ba79fc"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnet_a.id
  key_name = "lab5"

  // IAM role
  //iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  
  user_data = file("${path.module}/server_setup.sh")

  vpc_security_group_ids = [
    aws_security_group.cloud_project_group.id
  ]
  
  tags = {
    Name = "WebApp"
    OS = "RedHat"
  }

}


