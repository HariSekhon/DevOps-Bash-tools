#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-27 02:04:11 +0700 (Thu, 27 Feb 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Downloads and installs the latest Android SDK to ~/Android/Sdk/
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

cd /tmp

timestamp "Determining OS"
os="$(uname | tr '[:upper:]' '[:lower:]')"
timestamp "OS is: $os"

zip="platform-tools-latest-$os.zip"

timestamp "Downloading Android platform tools for OS '$os'"
wget -Nc "https://dl.google.com/android/repository/$zip"

mkdir -p -v ~/Android/Sdk

timestamp "Unzipping Android SDK platform tools to $HOME/Android/Sdk (overwrite)"
echo
unzip -o "$zip" -d ~/Android/Sdk

cat <<EOF

Now set these environment variables in your shell:

    export ANDROID_HOME="\$HOME/Android/Sdk"
    export PATH="\$PATH:\$ANDROID_HOME/platform-tools"
EOF
