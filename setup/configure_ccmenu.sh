#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-16 01:19:58 +0100 (Wed, 16 Oct 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

bin=/Applications/CCMenu.app/Contents/MacOS/CCMenu

plist_dir="Library/Containers/net.sourceforge.cruisecontrol.CCMenu/Data/Library/Preferences"

plist_file="net.sourceforge.cruisecontrol.CCMenu.plist"

"$srcdir/install_homebrew.sh"
echo

if ! [ -f "$bin" ]; then
    echo "================="
    echo "Installing CCMenu"
    echo "================="
    brew cask install ccmenu
    echo
fi

if ! pgrep CCMenu &>/dev/null; then
    echo "ensuring a first run has been done before replacing config, starting CCMenu"
    # need to ensure it's started before overwriting the config
    "$bin" &
    echo
    sleep 2
fi

#echo "Downloading CCMenu configuration from GitHub release"
#wget -c -O ~/Library/Containers/net.sourceforge.cruisecontrol.CCMenu/Data/Library/Preferences/net.sourceforge.cruisecontrol.CCMenu.plist \
#           https://github.com/HariSekhon/DevOps-Bash-tools/releases/download/ccmenu/net.sourceforge.cruisecontrol.CCMenu.plist

cd "$srcdir/.."

# CCMenu refuses to accept the configuration with a symlink
#ln -svf "$PWD/$plist_dir/$plist_file" ~/"$plist_dir/$plist_file"
rm -f ~/"$plist_dir/$plist_file"
cp -vf "$PWD/$plist_dir/$plist_file" ~/"$plist_dir/$plist_file"
echo

echo "Restarting CCMenu"
pkill -f "$bin" || :
echo
sleep 2

"$bin" &

disown

echo "Done"
