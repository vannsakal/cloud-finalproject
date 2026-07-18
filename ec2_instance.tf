
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

        // HTTP inbound

        ingress {

                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]

        }

        // SSH inbound

        ingress {

                from_port = 22
                to_port = 22
                protocol = "tcp"
                cidr_blocks = [var.my_ip]

        }

        egress {

                from_port = 0
                to_port = 0
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]


        }

    }


    # Resource block

    resource "aws_instance" "ec2_servers" {
        
        # create 2 instances
        count = 2   
        # instance image
        ami         =  "ami-02d23a03f80ba79fc"  
        # for high-availability
        availability_zone = element(["ap-southeast-1a", "ap-southeast-1b"], count.index) 
        instance_type = "t3.micro"
        # group
        security_groups = ["${aws_security_group.cloud_project_group.name}"]    
        key_name = "lab5"   

    # executing commands on the vm once boot

   user_data = <<-EOF
            #!/bin/bash
            dnf update -y
            dnf install -y nginx
            systemctl start nginx
            systemctl enable nginx
            echo "<h1>Hello from Terraform ${count.index + 1}</h1>" | tee /usr/share/nginx/html/index.html
    EOF

    # tags

    tags = {

        # Generates ec2 1 and 2
        Name = "WebServer-${count.index + 1}" 

    }

    }




        

