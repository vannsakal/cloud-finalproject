#!/bin/bash
dnf update -y
dnf install -y nginx
systemctl enable nginx.service
systemctl start nginx.service
echo "<h1> Hello from Terraform </h1>" | tee /usr/share/nginx/html/index.html

# Cloudflare tunnel
curl -fsSl https://pkg.cloudflare.com/cloudflared.repo | tee /etc/yum.repos.d/cloudflared.repo
dnf update -y
dnf install -y cloudflared
cloudflared service install ${cf_tunnel_token}