#!/bin/bash
set -e

NPMRC_FILE=".npmrc"

REPO2_URL="http://192.168.7.215:8081/repository/npm-br-proxy/"
REPO1_URL="http://192.168.7.250:8081/repository/npm-group/"

check_repo() {
  local url="$1"
  # Nexus responds with 200 (ok) or 401 (unauthorized) if alive
  if curl -s -o /dev/null -w "%{http_code}" --max-time 5 --connect-timeout 3 "$url" | grep -Eq "200|401"; then
    return 0
  else
    return 1
  fi
}

cp "$NPMRC_FILE" "${NPMRC_FILE}.bak"


sed -i 's/^[[:space:]]*registry=http:\/\/192\.168\.7\.250/# registry=http:\/\/192.168.7.250/' "$NPMRC_FILE"
sed -i 's#^[[:space:]]*//192\.168\.7\.250#\# //192.168.7.250#' "$NPMRC_FILE"

sed -i 's/^[[:space:]]*registry=http:\/\/192\.168\.7\.215/# registry=http:\/\/192.168.7.215/' "$NPMRC_FILE"
sed -i 's#^[[:space:]]*//192\.168\.7\.215#\# //192.168.7.215#' "$NPMRC_FILE"


if check_repo "$REPO1_URL"; then
  echo "✅ Repo1 ($REPO1_URL) is UP. Using it."
  sed -i 's/^#\s*registry=http:\/\/192\.168\.7\.250/registry=http:\/\/192.168.7.250/' "$NPMRC_FILE"
  sed -i 's/^#\s*\/\/192\.168\.7\.250/\/\/192\.168\.7\.250/' "$NPMRC_FILE"

elif check_repo "$REPO2_URL"; then
  echo "⚠️ Repo1 down, but Repo2 ($REPO2_URL) is UP. Using it."
  sed -i 's/^#\s*registry=http:\/\/192\.168\.7\.215/registry=http:\/\/192.168.7.215/' "$NPMRC_FILE"
  sed -i 's/^#\s*\/\/192\.168\.7\.215/\/\/192\.168\.7\.215/' "$NPMRC_FILE"

else
  echo "❌ Both Nexus repos are DOWN. Leaving all commented out."
fi

echo "----- Final .npmrc config -----"
cat "$NPMRC_FILE"
