#!/usr/bin/env bash
# Bootstrap only: fetches the private A/B code with a read-only deploy key held in the host's secret env.
set -euo pipefail
mkdir -p "$HOME/.ssh"
printf '%s' "$DEPLOY_KEY_B64" | base64 -d > "$HOME/.ssh/ab_deploy"
chmod 600 "$HOME/.ssh/ab_deploy"
rm -rf app
GIT_SSH_COMMAND="ssh -i $HOME/.ssh/ab_deploy -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" \
  git clone --depth 1 --branch "${AB_BRANCH:-main}" git@github.com:Nimadamus/kalshi-shadow-ab.git app
rm -f "$HOME/.ssh/ab_deploy"
pip install -r app/requirements.txt
