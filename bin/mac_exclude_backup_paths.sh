#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-04-14 04:30:02 +0800 (Mon, 14 Apr 2025)
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

export HOME="${HOME:-$(cd && pwd)}"

excluded_paths="
$HOME/.cache
$HOME/.cpan
$HOME/.cpanm
$HOME/.crc
$HOME/.docker/machine/cache
$HOME/.docker/machine/machines
$HOME/.gem
$HOME/.gradle
$HOME/.groovy
$HOME/.ivy
$HOME/.ivy2
$HOME/.m2
$HOME/.minikube
$HOME/.sbt
$HOME/Library/Application Support/Spotify/PersistentCache
$HOME/Library/Application Support/multipass/
$HOME/Library/Caches/Homebrew
$HOME/Library/Caches/pip
$HOME/Library/Containers/com.docker.docker
$HOME/Library/Developer/Xcode/DerivedData
$HOME/Library/Logs/rancher-desktop
$HOME/Library/State/rancher-desktop
$HOME/Library/State/rancher-desktop
$HOME/VirtualBox VMs
$HOME/go/bin
$HOME/go/pkg
$HOME/go/src/github.com
$HOME/go/src/golang.org
"

if [ -n "${GOPATH:-}" ]; then
    excluded_paths+="
$GOPATH/bin
$GOPATH/pkg
$GOPATH/src/github.com
$GOPATH/src/golang.org
    "
fi

excluded_paths="$(sort -u <<< "$excluded_paths" | sed '/^[[:space:]]*$/d')"

# shellcheck disable=SC2034,SC2154
usage_description="
Excludes many common large caches, docker and VM paths from macOS Time Machine backups

Must be either run as root or will attempt to use sudo to add each path

See HariSekhon/Knowledge-Base Mac page for more details on Time Machine path exclusions:

    https://github.com/HariSekhon/Knowledge-Base/blob/main/mac.md#time-machine

By default excludes the following common paths:

$excluded_paths

Find more paths to add as args using this command:

    du -max ~ | sort -k1n | tail -n 1000
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<path> <path2>...]"

help_usage "$@"

#min_args 1 "$@"

mac_only

timestamp "Excluding paths from macOS Time Machine backups"

exclude_path(){
    local path="$1"
    path="${path## }"
    path="${path%% }"
    if is_blank "$path"; then
        return
    fi
    timestamp "Adding path to macOS Time Machine exclusions: $path"
    # defined in lib/utils-bourne.sh
    # shellcheck disable=SC2154
    "$sudo" tmutil addexclusion -p "$path"
}

for path in "$@"; do
    exclude_path "$path"
done

while read -r path; do
    exclude_path "$path"
done <<< "$excluded_paths"

timestamp "Done"
