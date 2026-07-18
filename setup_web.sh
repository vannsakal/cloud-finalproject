sudo dnf update -y
sudo dnf install -y nginx
systemctl start nginx
sysytectl enable nginx
echo "<h1> Hello from Terraform User</h1>" > /usr/share/nginx/html/
