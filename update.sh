#!/usr/bin/env bash
# Pull the latest private A/B code with the read-only deploy key and restart the paper A/B service.
set -euo pipefail
sudo -u ab bash -c 'cd /opt/ab/app && GIT_SSH_COMMAND="ssh -i /etc/ab/deploy_key -o IdentitiesOnly=yes" git pull -q && git log --oneline -1 && /opt/ab/venv/bin/pip install -q -r requirements.txt'
systemctl restart kalshi-ab
sleep 3
systemctl is-active kalshi-ab
free -m | head -2
timedatectl | grep -i -E "synchron|NTP"
