
# Terraform setting block 

terraform {

   required_providers{
	
	aws = {

	  source = "hashicorp/aws"

	}
   }

}

# Provider block

provider "aws" {

	profile = "default"
	region = "ap-southeast-1"

}

# security group

resource "aws_security_group" "cloud_project_group" {

	name = "cloud_project_group"
	description = "allow ssh, http, and more" 

	// web access

	ingress {

			from_port = 443
			to_port = 443
			protocol = "tcp"
			cidr_blocks = ["0.0.0.0/0"]

	}

	// ssh access

	ingress {

			from_port = 20
			to_port = 20
			protocol = "tcp"
			cidr_blocks = ["0.0.0.0/24"]

	}

	egress {

			from_port = 0
			to_port = 0
			protocol = "-1"
			cidr_blocks = ["0.0.0.0/0"]


	}

}


# Resource block

resource "aws_instance" "ec2_first_cloud" {

	ami         =  "ami-02d23a03f80ba79fc"
	availability_zone = "ap-southeast-1a"
	instance_type = "t3.micro"
	security_groups = ["${aws_security_group.cloud_project_group.name}"]

# executing commands on the vm once boot

user_data = file("${path.module}/setup_web.sh")

# tags

tags = {

	Name = "WebServer"

}

}




	


