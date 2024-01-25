#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-26 17:34:18 +0100 (Tue, 26 Jul 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.github.com/en/code-security/code-scanning/using-codeql-code-scanning-with-your-existing-ci-system/installing-codeql-cli-in-your-ci-system
#
# https://docs.github.com/en/code-security/code-scanning/using-codeql-code-scanning-with-your-existing-ci-system/configuring-codeql-cli-in-your-ci-system

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs GitHub CodeQL CLI + bundle to \$HOME/bin
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#version="${1:-2.10.1}"
#version="${1:-latest}"

os="$(get_os)"
if [ "$os" = darwin ]; then
    os=osx
fi

# github/codeql only has source not binary, and it cannot be extracted via github_install_binary.sh - it must be run from the bundle, which is ~500MB

                          # 64 - there are no i386 or other binaries
tarball="codeql-bundle-${os}64.tar.gz"

#tmp="$(mktemp -d)"
#trap_cmd 'rm -fr "$tmp"'

# better for caching, use flock instead
tmp=/tmp

cd "$tmp"

timestamp "Downloading latest codeql tarball"
echo
wget -cO "$tarball" "https://github.com/github/codeql-action/releases/latest/download/$tarball"
echo

timestamp "Extracting tarball"
echo
rm -fr -- ./codeql
tar xvzf ./"$tarball"  # -C ~/bin/  # mv is more atomic, otherwise concurrent operations using codeql might break
echo

unalias rm &>/dev/null || :
unalias mv &>/dev/null || :

timestamp "Removing tarball"
echo
rm -fv -- "$tarball"
echo

timestamp "Moving CodeQL to \$HOME/bin/"
echo
rm -fr -- ~/bin/codeql
mv -fv -- codeql/ ~/bin/
echo

echo "Version:"
~/bin/codeql/codeql version
echo
echo "Don't forget to add \$HOME/bin/codeql to \$PATH"
echo
