#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-24 04:21:37 +0400 (Sun, 24 Nov 2024)
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
For every AWS profile found in the given \$AWS_CONFIG_FILE or given file argument

Useful to take a large generated AWS config.ini from script:

    aws_sso_configs.sh

and then split it into subdirectories for direnvs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<aws_config>]"

help_usage "$@"

max_args 1 "$@"

config="${1:-${AWS_CONFIG_FILE:-$HOME/.aws/config}}"

if ! [ -f "$config" ]; then
    die "ERROR: file does not exist: $config"
fi

grep -Eo "^[[:space:]]*\[profile .+\]" "$config" |
sed 's/.*\[profile//; s/\].*$//' |
while read -r profile; do
    if is_blank "$profile"; then
        continue
    fi
    if ! [[ "$profile" =~ ^[[:alnum:]_-]+$ ]]; then
        warn "profile '$profile' failed regex validation, skipping for safety..."
        continue
    fi
    mkdir -p "$profile"
    dest="$profile/config.ini"
    timestamp "Generating $dest"
    "$srcdir/../data/ini_grep_section.sh" "$config" "profile $profile" > "$dest"
    if ! [ -s "$dest" ]; then
        die "Failed to generate $dest"
    fi
done
