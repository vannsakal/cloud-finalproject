#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y nginx python3 python3-pip unzip jq amazon-cloudwatch-agent

###########################
##### FETCH THE APP #######
###########################

aws s3 cp "s3://${s3_bucket}/${s3_key}" /opt/webapp.zip --region "${region}"
mkdir -p /opt/webapp
unzip -o /opt/webapp.zip -d /opt/webapp
mkdir -p /var/log/webapp

###########################
##### FETCH DB CREDS #######
###########################

SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "${secret_arn}" \
  --region "${region}" \
  --query SecretString --output text)

DB_HOST=$(echo "$SECRET_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin)['host'])")
DB_PORT=$(echo "$SECRET_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin)['port'])")
DB_USER=$(echo "$SECRET_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin)['username'])")
DB_PASS=$(echo "$SECRET_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin)['password'])")
DB_NAME=$(echo "$SECRET_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin)['dbname'])")

cat >/etc/webapp.env <<EOF
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_NAME=$DB_NAME
EOF
chmod 600 /etc/webapp.env

###########################
###### PYTHON DEPS ########
###########################

pip3 install -r /opt/webapp/requirements.txt

###########################
### IDEMPOTENT DB INIT #####
###########################
# RDS may still be finishing setup on first boot, so retry for a bit before giving up

python3 - <<'PYEOF'
import os, sys, time
import mysql.connector

env = {}
with open('/etc/webapp.env') as f:
    for line in f:
        k, v = line.strip().split('=', 1)
        env[k] = v

for attempt in range(15):
    try:
        conn = mysql.connector.connect(
            host=env['DB_HOST'], port=int(env['DB_PORT']),
            user=env['DB_USER'], password=env['DB_PASS'], database=env['DB_NAME']
        )
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                message TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        conn.close()
        print("DB schema ready")
        break
    except mysql.connector.Error as e:
        print(f"DB not ready yet ({attempt+1}/15): {e}", file=sys.stderr)
        time.sleep(10)
else:
    print("Giving up waiting on DB, app will report DB errors until it recovers", file=sys.stderr)
PYEOF

###########################
##### SYSTEMD SERVICE #####
###########################

cat >/etc/systemd/system/webapp.service <<'EOF'
[Unit]
Description=Flask webapp (gunicorn)
After=network.target

[Service]
WorkingDirectory=/opt/webapp
EnvironmentFile=/etc/webapp.env
ExecStart=/usr/local/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 \
  --access-logfile /var/log/webapp/access.log --error-logfile /var/log/webapp/error.log app:app
Restart=always
RestartSec=5
User=nginx

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable webapp.service
systemctl restart webapp.service

###########################
###### NGINX PROXY ########
###########################

rm -f /etc/nginx/conf.d/default.conf
cat >/etc/nginx/conf.d/webapp.conf <<'EOF'
server {
    listen 80;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

systemctl enable nginx
systemctl restart nginx

###########################
##### CLOUDWATCH AGENT ####
###########################

cat >/opt/aws-cwagent-config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "${log_group}",
            "log_stream_name": "{instance_id}/nginx-access"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "${log_group}",
            "log_stream_name": "{instance_id}/nginx-error"
          },
          {
            "file_path": "/var/log/webapp/error.log",
            "log_group_name": "${log_group}",
            "log_stream_name": "{instance_id}/webapp-error"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CloudFinalProject",
    "metrics_collected": {
      "mem": { "measurement": ["mem_used_percent"] },
      "disk": { "measurement": ["used_percent"], "resources": ["/"] }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws-cwagent-config.json -s
