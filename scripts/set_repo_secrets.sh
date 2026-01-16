#!/bin/bash
set -e

# Interactive script to set GitHub repository secrets
#
# Example usage:
#
#   ./scripts/set_repo_secrets.sh
#
# The script will prompt for each secret:
#   - TARGET_HOST: example.com
#   - TARGET_USER: deploy
#   - KNOWN_HOSTS: (paste output of: ssh-keyscan example.com)
#   - PRIVATE_KEY: (paste your SSH private key, then Ctrl+D)
#   - NTFY_TOPIC: my-notifications

# Define secrets to set
SECRETS=(
  "TARGET_HOST:Deployment target hostname"
  "TARGET_USER:SSH user for deployment"
  "KNOWN_HOSTS:SSH known_hosts entry"
  "PRIVATE_KEY:SSH private key (multiline)"
  "NTFY_TOPIC:Notification topic name"
)

echo "Setting GitHub repository secrets..."
echo

for secret_info in "${SECRETS[@]}"; do
  IFS=':' read -r secret_name description <<< "$secret_info"

  echo "Setting $secret_name ($description)"

  if [[ "$secret_name" == "PRIVATE_KEY" ]]; then
    echo "Enter/paste the SSH private key (Ctrl+D when done):"
    secret_value=$(cat)
  else
    read -p "Enter value: " secret_value
  fi

  if [[ -z "$secret_value" ]]; then
    echo "Warning: Empty value for $secret_name, skipping..."
    continue
  fi

  gh secret set "$secret_name" --body "$secret_value"
  echo "✓ $secret_name set successfully"
  echo
done

echo "All secrets have been set!"
