#!/usr/bin/env bash
# One-time host setup for the paper-only Kalshi A/B (Ubuntu 22.04, Python 3.10). Contains no application code
# and no secrets: DEPLOY_KEY_B64 (read-only GitHub deploy key) and VIEW_TOKEN arrive in the environment.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y python3-venv python3-pip git
timedatectl set-timezone UTC || true
timedatectl set-ntp true || true
id ab >/dev/null 2>&1 || useradd -m -s /bin/bash ab
mkdir -p /data /opt/ab /etc/ab
chown ab:ab /data /opt/ab
umask 077
printf '%s' "$DEPLOY_KEY_B64" | base64 -d > /etc/ab/deploy_key
chown ab:ab /etc/ab/deploy_key
cat > /etc/ab/env <<EOF
DATA_DIR=/data
PORT=8080
VIEW_TOKEN=${VIEW_TOKEN}
EOF
chmod 600 /etc/ab/env
sudo -u ab bash -c '
set -e
cd /opt/ab
rm -rf app
GIT_SSH_COMMAND="ssh -i /etc/ab/deploy_key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" \
  git clone --depth 1 git@github.com:Nimadamus/kalshi-shadow-ab.git app
python3 -m venv venv
venv/bin/pip install -q -r app/requirements.txt
'
cat > /etc/systemd/system/kalshi-ab.service <<'EOF'
[Unit]
Description=Paper-only Kalshi A/B (cloud shadow control, defined model, shared market-data feed)
After=network-online.target
Wants=network-online.target

[Service]
User=ab
WorkingDirectory=/opt/ab/app
EnvironmentFile=/etc/ab/env
ExecStart=/opt/ab/venv/bin/python /opt/ab/app/run_all.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now kalshi-ab.service
echo "kalshi-ab setup done $(date -u)" > /var/log/kalshi-ab-setup.done
