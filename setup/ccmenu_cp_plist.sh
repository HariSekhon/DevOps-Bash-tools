#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-11-02 20:53:06 +0000 (Sat, 02 Nov 2019)
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

plist_dir="Library/Containers/net.sourceforge.cruisecontrol.CCMenu/Data/Library/Preferences"

plist_file="net.sourceforge.cruisecontrol.CCMenu.plist"

cd "$srcdir/.."

cp -vf -- ~/"$plist_dir/$plist_file" "$PWD/$plist_dir/$plist_file"
plutil -convert xml1 "$PWD/$plist_dir/$plist_file"
echo

echo "git diff $PWD/$plist_dir/$plist_file"
git diff "$PWD/$plist_dir/$plist_file"
