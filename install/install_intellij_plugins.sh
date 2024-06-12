#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-06-12 18:15:16 +0200 (Wed, 12 Jun 2024)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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
. "$srcdir/../lib/utils.sh"

plugins_txt="$srcdir/../setup/intellij-plugins.txt"

plugins_txt="$(readlink -f "$plugins_txt" || die "Failed to find file: $srcdir/../setup/intellij-plugins.txt")"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs IntelliJ Plugins listed in $plugins_txt

Edit this file to add/comment/uncomment lines to select the plugins you want
and then run this script to install them all in one shot
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_more_args "$@"

timestamp "Parsing Plugin List"
echo
plugin_list="$(
    sed '
        s/#.*//;
        s/^[[:space:]]*//;
        s/[[:space:]]*$//;
        /^[[:space:]]*$/d;
    ' "$plugins_txt" |
    while read -r plugin; do
        if [[ "$plugin" =~ [[:space:]] ]]; then
            echo "'$plugin'"
        else
            echo "$plugin"
        fi
    done
)"

timestamp "Plugins List:"
echo
echo "$plugin_list"
echo

timestamp "Installing Plugins"
# want to interpret quotes
# shellcheck disable=SC2086
eval idea installPlugins $plugin_list

timestamp "Plugins Installation Complete"
