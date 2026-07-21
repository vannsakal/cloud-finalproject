# Dynamodb table to lock Terraform state

terraform {
  backend "s3" {
    bucket       = "terraform-statefile-dingdong-bucket"
    key          = "project/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}