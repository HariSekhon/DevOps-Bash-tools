#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-16 01:19:58 +0100 (Wed, 16 Oct 2019)
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

bin=/Applications/CCMenu.app/Contents/MacOS/CCMenu

plist_dir="Library/Containers/net.sourceforge.cruisecontrol.CCMenu/Data/Library/Preferences"

plist_file="net.sourceforge.cruisecontrol.CCMenu.plist"

"$srcdir/../install/install_homebrew.sh"
echo

if ! [ -f "$bin" ]; then
    echo "================="
    echo "Installing CCMenu"
    echo "================="
    brew cask install ccmenu
    echo
fi

#if ! pgrep CCMenu &>/dev/null; then
#    echo "ensuring a first run has been done before replacing config, starting CCMenu"
#    # need to ensure it's started before overwriting the config
#    "$bin" &
#    echo
#    sleep 2
#fi

#echo "Downloading CCMenu configuration from GitHub release"
#wget -c -O ~/Library/Containers/net.sourceforge.cruisecontrol.CCMenu/Data/Library/Preferences/net.sourceforge.cruisecontrol.CCMenu.plist \
#           https://github.com/HariSekhon/DevOps-Bash-tools/releases/download/ccmenu/net.sourceforge.cruisecontrol.CCMenu.plist

cd "$srcdir/.."

echo "Killing CCMenu"
pkill -f "$bin" || :
echo

while pgrep CCMenu &>/dev/null; do
    echo "waiting for CCMenu to go down"
    sleep 1
    if [ $SECONDS -gt 30 ]; then
        echo "Timed out waiting for CCMenu to go down"
        exit 1
    fi
done

#mkdir -pv ~/"$plist_dir/"
#rm -f ~/"$plist_dir/$plist_file"
#echo "Removing ~/Library/Containers/net.sourceforge.cruisecontrol.CCMenu/Container.plist"
#rm -f ~/Library/Containers/net.sourceforge.cruisecontrol.CCMenu/Container.plist
# these don't take immediate effect due to caching, so load via 'defaults' instead
#echo "Linking CCMenu configuration:"
#ln -svf "$PWD/$plist_dir/$plist_file" ~/"$plist_dir/$plist_file"
#echo "Copying CCMenu configuration:"
#cp -vf "$PWD/$plist_dir/$plist_file" ~/"$plist_dir/$plist_file"
echo "Loading CCMenu configuration"
# give file or pipe via stdin
#defaults import net.sourceforge.cruisecontrol.CCMenu "$PWD/$plist_dir/$plist_file"
defaults import net.sourceforge.cruisecontrol.CCMenu - < "$PWD/$plist_dir/$plist_file"
echo

echo "Starting CCMenu"
#"$bin" &
#disown
open -a CCMenu

echo "Done"
