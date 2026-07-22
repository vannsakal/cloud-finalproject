variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "ap-southeast-1"
}

variable "main_vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_range_a" {
  description = "CIDR block for public subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_range_b" {
  description = "CIDR block for public subnet B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_range_a" {
  description = "CIDR block for private subnet A"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_range_b" {
  description = "CIDR block for private subnet B"
  type        = string
  default     = "10.0.4.0/24"
}

# AZ

variable "availability_zone" {
  description = "List of availability_zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

# EC2 instance configuration

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-02d23a03f80ba79fc"

}

# EC2 instance_type for ASG instances

variable "instance_type" {
  description = "Instance type for EC2 instance"
  type        = string
  default     = "t3.micro"
}

# Desired number of instances in the Auto Scaling Group

variable "desired_capacity" {
  description = "Desired number of instances for ASG"
  type        = number
  default     = 2
}

# Minimum number of instances in the Auto Scaling Group

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 2
}

# Maximum number of instances in the Auto Scaling Group

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 5
}



# S3 Bucket Configuration
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "cloud-finalproject-s3-bucket-2026"
}

###########################
######## RDS (MySQL) ######
###########################

variable "db_name" {
  description = "Initial database name created on the RDS instance"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "appadmin"
}

variable "db_engine_version" {
  description = "MySQL engine version for RDS"
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

###########################
######## Alerting #########
###########################

variable "alert_email" {
  description = "Email address to subscribe to CloudWatch alarm notifications. Leave empty to skip the subscription."
  type        = string
  default     = ""
}
