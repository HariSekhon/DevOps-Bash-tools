#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-13 23:48:38 +0700 (Mon, 13 Jan 2025)
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
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Checks out all public original source GitHub repos for the current or given user
and then counts all lines of code for them with breakdowns of languages, files,
code, comments and blanks

Uses GitHub CLI and cloc - attempts to install them if not found
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<owner>]"

help_usage "$@"

max_args 1 "$@"

owner="${1:-}"

export HOME="${HOME:-$(cd && pwd)}"

export PATH="$PATH:$HOME/bin"

if ! type -P gh &>/dev/null; then
    timestamp "GitHub CLI not found, attempting to install..."
    echo
    "$srcdir/../packages/install_packages.sh" gh ||
    "$srcdir/../install/install_github_cli.sh"
    echo
fi

if ! type -P cloc &>/dev/null; then
    timestamp "cloc not found, attempting to install..."
    echo
    "$srcdir/../packages/install_packages.sh" cloc
    echo
fi

timestamp "Getting list of public original GitHub repo urls"
github_repo_urls="$(get_github_repo_urls ${owner:+"$owner"} --visibility public --source)"
num_github_repo_urls="$(wc -l <<< "$github_repo_urls" | sed 's/[[:space:]]*//g')"
timestamp "Found $num_github_repo_urls GitHub repos"
echo

tmp="/tmp/github-checkouts"

mkdir -p -v "$tmp"

timestamp "Switching to dir: $tmp"
cd "$tmp"
echo

timestamp "Checking out all public original GitHub repos"
echo
while read -r github_repo_url; do
    dir="${github_repo_url##*/}"
    if [ -d "$dir" ]; then
        timestamp "Pulling $github_repo_url"
        pushd "$dir"
        git pull
        popd
    else
        timestamp "Cloning $github_repo_url"
        git clone "$github_repo_url"
    fi
    echo
done <<< "$github_repo_urls"
timestamp "Cloning done"
echo

timestamp "Counting lines of code:"
echo
cloc .
