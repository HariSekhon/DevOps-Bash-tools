#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-07 06:07:05 +0400 (Thu, 07 Nov 2024)
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
Uploads a file to https://termbin.com and copies the resulting URL to your clipboard

Prompts to confirm the content before uploading for your safe review as this is PUBLIC

Recommended: use anonymize.py or anonymize.pl from the adjacent DevOps-Python-tools or DevOps-Perl-tools repos

Optional: decomment.sh

There is no syntax highlighting on https://termbin.com

Knowledge Base page: https://github.com/HariSekhon/Knowledge-Base/blob/main/upload-sites.md

Requires nc or ncat or netcat to be installed

Attempts to install netcat on common systems like RHEL / Debian / Ubuntu / Alpine / Mac if needed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename>"

help_usage "$@"

min_args 1 "$@"

file="$1"

if ! file "$file" | grep -q ASCII; then
    die "This is only for text files like code. For non-text files use adjacent 0x0.sh"
fi

nc=nc

if type -P nc &>/dev/null; then
    :
elif type -P ncat &>/dev/null; then
    nc=ncat
elif type -P netcat &>/dev/null; then
    nc=netcat
elif is_mac; then
    "$srcdir/../packages/brew_install_packages.sh" netcat
elif type -P yum &>/dev/null ||
     type -P apt-get &>/dev/null; then
    "$srcdir/../packages/install_packages.sh" nc
elif type -P apk &>/dev/null; then
    "$srcdir/../packages/apk_install_packages.sh" netcat-openbsd
else
    die "No netcat program installed: nc, ncat or netcat"
fi

# Do not allow reading from stdin because it does not allow the prompt safety
#if [ "$file" = '-' ]; then
#    timestamp "reading from stdin"
    #file="/dev/stdin"
#else
    timestamp "reading from file: $file"
#fi

content="$(cat "$file")"
echo

cat <<EOF
Here is what will be uploaded to termbin:

$content

EOF

read -r -p "Continue? [y/N] " answer
echo

check_yes "$answer"
echo

"$nc" termbin.com 9999 <<< "$content" |
tee /dev/stderr |
"$srcdir/../bin/copy_to_clipboard.sh"
echo
