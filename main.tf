# Create the VPC (isolated private network in aws)

resource "aws_vpc" "main" {

  cidr_block       = var.main_vpc_cidr
  instance_tenancy = "default" # shared hardware, cheaper I guess
  // enable_dns_hostnames = true # we are using cloudflare tunnel
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

# Create 4 subnets: two private and two public

resource "aws_subnet" "public_subnet_a" {

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_range_a
  map_public_ip_on_launch = true # any instances launched in this subnet automatically gets a public IP address
  availability_zone       = var.availability_zone[0]
  tags = {
    "Name" = "${var.environment}-public-subnet-a"
  }

}

resource "aws_subnet" "public_subnet_b" {

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_range_b
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone[1]
  tags = {
    "Name" = "${var.environment}-public-subnet-b"
  }

}

resource "aws_subnet" "private_subnet_a" {

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_range_a
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zone[0]
  tags = {
    "Name" = "${var.environment}-private-subnet-a"
  }

}

resource "aws_subnet" "private_subnet_b" {

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_range_b
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zone[1]
  tags = {
    "Name" = "${var.environment}-private-subnet-b"
  }

}

# Create Route table for Public Subnets

resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.main.id
  route {

    # Traffic from Public Subnet reaches Internet via Internet Gateway
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    "Name" = "${var.environment}-public-route-table"
  }

}

# Create Route table for Private Subnets

resource "aws_route_table" "private_rt_a" {

  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${var.environment}-private-route-table"
  }

}

resource "aws_route_table" "private_rt_b" {

  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${var.environment}-private-route-table"
  }

}


# Route table Association with Private Subnet A

resource "aws_route_table_association" "private_rt_association_a" {

  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt_a.id # attach the Private route table to the subnet to follow the rules

}

# Route table Association with Private Subnet B

resource "aws_route_table_association" "private_rt_association_b" {

  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt_b.id # attach the Private route table to the subnet to follow the rules

}

###########################
####### NAT GATEWAYS ######
###########################

# AWS Elastic IP, this is a static Public IPv4

resource "aws_eip" "nat-a" {
  domain = "vpc"
  tags = {
    Name = "${var.environment}-nat-gw-a"
  }
}

resource "aws_eip" "nat-b" {
  domain = "vpc"
  tags = {
    Name = "${var.environment}-nat-gw-b"
  }
}

# NAT Gateways placed in the PUBLIC subnets (they need the IGW)

resource "aws_nat_gateway" "nat-a" {
  allocation_id = aws_eip.nat-a.id
  subnet_id     = aws_subnet.public_subnet_a.id # NAT gateway must be in public subnet
  tags = {
    Name = "${var.environment}-nat-gw-a"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat-b" {
  allocation_id = aws_eip.nat-b.id
  subnet_id     = aws_subnet.public_subnet_b.id # NAT gateway must be in public subnet
  tags = {
    Name = "${var.environment}-nat-gw-b"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "private_nat_route_a" {
  route_table_id         = aws_route_table.private_rt_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-a.id # tell these bitch ass instances to send traffic to the NAT to reach internet
}

resource "aws_route" "private_nat_route_b" {
  route_table_id         = aws_route_table.private_rt_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-b.id # tell these bitch ass instances to send traffic to the NAT to reach internet
}

# Route table Association with Public Subnet A

resource "aws_route_table_association" "public_rt_association_a" {

  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id

}

resource "aws_route_table_association" "public_rt_association_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

###########################
########### ASG ###########
###########################

resource "aws_autoscaling_group" "terraform_asg" {
  name                = "dingdong-asg"
  min_size            = var.min_size                                                     # 2 instances must always be running
  max_size            = var.max_size                                                     # maximum instances
  desired_capacity    = var.desired_capacity                                             # 2, if one crash, spin up another one bih ah Pheaktra
  vpc_zone_identifier = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id] # ayo, put these fking instances in these subnets

  target_group_arns = [aws_lb_target_group.reverse_proxy.arn] # associate me with them balancer

  # Define the launch template used by the ASG for creating instances
  launch_template {
    id      = aws_launch_template.launch-asg.id # launch using our template
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "terraform-asg"
    propagate_at_launch = true
  }

}

# ASG Launch Template aka. EC2

resource "aws_launch_template" "launch-asg" {
  name          = "my-launch-asg"
  image_id      = var.ami_id
  instance_type = var.instance_type
  user_data = base64encode(templatefile("${path.module}/server_setup.sh.tpl", {
    region     = var.aws_region
    s3_bucket  = aws_s3_bucket.secure_bucket.id
    s3_key     = aws_s3_object.webapp_package.key
    secret_arn = aws_secretsmanager_secret.db_secret.arn
    log_group  = aws_cloudwatch_log_group.webapp_logs.name
  }))

  vpc_security_group_ids = [aws_security_group.asg_sg.id] # attach the firewall or sg

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name # assign role to our ec2, to say fk the ssh key, we dont need that
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "MyLaunchASGInstance"
    }
  }
}
###########################
####### S3 BUCKET #########
###########################

resource "aws_s3_bucket" "secure_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_crypto" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
