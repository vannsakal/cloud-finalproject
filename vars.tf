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
##### S3 bucket #######
variable "bucket_name" {
  type    = string
  default = "cloud-finalproject-bucket-sam-unique-2026"
}
