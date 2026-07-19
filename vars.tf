variable "environment" {}
variable "aws_region" {}
variable "main_vpc_cidr" {}
variable "public_subnet_range_a" {}
variable "private_subnet_range_a" {}
variable "private_subnet_range_b" {}
variable "my_ip" {
    description = "allow ssh from my computer"
    type = string
}