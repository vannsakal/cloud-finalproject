#!/bin/bash
set -uo pipefail
exec > /var/log/user-data.log 2>&1

dnf update -y
dnf install -y nginx
systemctl enable nginx.service --now


# RDS and WebServer

# Python + deps
# dnf install -y python3-pip git mysql
dnf install -y python3-pip git mariadb105
pip3 install flask gunicorn mysql-connector-python

# Deploy webapp
if git clone https://github.com/vannsakal/cloud-finalproject.git /tmp/repo; then
    cp -r /tmp/repo/webapp/* /usr/share/nginx/html/
    rm -rf /tmp/repo
else
    echo "WARN: git clone failed — webapp not deployed"
fi

# Wait for RDS then create table
export MYSQL_PWD="${db_password}"
for i in $(seq 1 30); do
    if mysql -h ${rds_endpoint} -P ${rds_port} -u ${db_username} ${db_name} -e "
        CREATE TABLE IF NOT EXISTS messages (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            message TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );"; then
        echo "RDS ready — table created"
        break
    fi
    echo "Waiting for RDS ($${i}/30)..."
    sleep 10
done
unset MYSQL_PWD

# Env file (no creds in systemd unit)
cat > /etc/webapp.env <<-EOF
DB_HOST=${rds_endpoint}
DB_PORT=${rds_port}
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASS=${db_password}
EOF
chmod 600 /etc/webapp.env

# systemd unit
cat > /etc/systemd/system/webapp.service <<-UNIT
[Unit]
Description=Flask App
After=network.target

[Service]
WorkingDirectory=/usr/share/nginx/html
EnvironmentFile=/etc/webapp.env
ExecStart=/usr/local/bin/gunicorn -w 2 -b 0.0.0.0:5000 app:app
Restart=always
User=root

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now webapp.service

# Nginx reverse proxy
cat > /etc/nginx/conf.d/default.conf <<-EOF
server {
    listen 80;
    location / {
        proxy_pass http://127.0.0.1:5000;
    }
}
EOF
systemctl restart nginx