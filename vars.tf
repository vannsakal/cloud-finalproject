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
  default     = "10.0.0.0/24"   
}

variable "private_subnet_range_a" {
  description = "CIDR block for private subnet A"
  type        = string
  default     = "10.0.1.0/24"  
}

variable "private_subnet_range_b" {
  description = "CIDR block for private subnet B"
  type        = string
  default     = "10.0.2.0/24"   
}

variable "my_ip" {
    description = "allow ssh from my computer"
    type = string
}
##### S3 bucket #######
variable "bucket_name" {
  type    = string
  default = "cloud-finalproject-bucket-sam-unique-2026"
}

variable "cf_tunnel_token" {
  description = "Cloudflare tunnel token"
  type        = string
}

variable "domain_name" {
  description = "Cloudflare domain"
  type        = string
  default     = "cloud-aws.sybau-ctf.space"
}
