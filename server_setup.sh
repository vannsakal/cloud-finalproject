#!/bin/bash
dnf update -y
dnf install -y nginx
systemctl enable nginx.service
systemctl start nginx.service
echo "<h1> Hello from Terraform $(hostname -I) </h1>" | tee /usr/share/nginx/html/index.html
