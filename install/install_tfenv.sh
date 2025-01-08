#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-08 12:44:50 +0700 (Wed, 08 Jan 2025)
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
Installs tfenv for managing Terraform versions
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

export HOME="${HOME:-$(cd && pwd)}"

export PATH="$HOME/.tfenv/bin:$PATH"

if is_mac; then
    brew install tfenv
else
    if [ -d ~/.tfenv ]; then
        cd ~/.tfenv
        timestamp "Git pulling in existing ~/.tfenv dir"
        echo
        git pull
        echo
    else
        timestamp "Git cloning the tfenv github repo to ~/.tfenv"
        echo >&2
        git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
    fi
    echo
    echo "Don't forget to add ~/.tfenv/bin to your \$PATH in your ~/.bashrc or similar"
    echo
    echo "(already done if sourcing DevOps-Bash-tools repo's .bashrc using .bash.d/terraform.sh)"
    echo
fi
echo

echo -n "tfenv version: "
tfenv version-name
echo
