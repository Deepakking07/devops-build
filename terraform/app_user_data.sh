#!/bin/bash
# =========================
# App Server Bootstrap Script
# =========================

# --- Basic updates and tools ---
apt-get update -y
apt-get install -y docker.io curl wget
systemctl enable --now docker

# --- Install Docker Compose ---
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# --- Docker Hub login (YOUR account) ---
# Username is fixed; password must come from env var DOCKER_PASSWORD
DOCKER_USERNAME="deepakk007"
DOCKER_PASSWORD="${DOCKER_PASSWORD:-CHANGE_ME}"

if [ "$DOCKER_PASSWORD" != "CHANGE_ME" ]; then
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
fi

# --- Pull and run latest image from your prod repo ---
REPO="deepakk007/project3-prod"

docker pull "${REPO}:latest" || exit 1

# Stop/remove old container if present
if docker ps -a --format '{{.Names}}' | grep -q '^react-app$'; then
  docker stop react-app || true
  docker rm react-app || true
fi

# Run container on port 80
docker run -d --name react-app -p 80:80 "${REPO}:latest"

# =========================
# CloudWatch Logs Agent
# =========================

cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

mkdir -p /opt/aws/amazon-cloudwatch-agent/bin

cat <<EOF >/opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/lib/docker/containers/*/*.log",
            "log_group_name": "/aws/react-app",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
