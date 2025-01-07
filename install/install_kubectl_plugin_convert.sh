#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-01 04:14:29 +0700 (Wed, 01 Jan 2025)
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
Installs the latest version of the kubectl-convert plugin

Also pre-installs kubectl if not already present
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

export HOME="${HOME:-$(cd && pwd)}"

export PATH="$PATH:$HOME/bin"

if ! type -P kubectl &>/dev/null; then
    timestamp "Kubectl not installed, pre-installing..."
    echo
    "$srcdir/install_kubectl.sh"
    echo
fi

timestamp "Getting latest stable version number"
version="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
timestamp "Stable version is: $version"

echo

os="$(get_os)"
arch="$(get_arch)"

timestamp "Downloading kubectl-convert version '$version' for '$os' arch '$arch'"
echo
wget -c "https://dl.k8s.io/release/$version/bin/$os/$arch/kubectl-convert"
echo
timestamp "Downloaded binary"

echo

timestamp "Getting SHA checksum"
echo
wget -c "https://dl.k8s.io/release/$version/bin/$os/$arch/kubectl-convert.sha256"
echo
timestamp "Downloaded checksum"

echo

timestamp "Checking SHA checksum"
echo "$(cat kubectl-convert.sha256) kubectl-convert" |
sha256sum --check #<<< "$(cat kubectl-convert.sha256) kubectl-convert"

echo

# doesn't support file://
#"$srcdir/../packages/install_binary.sh" "file://$PWD/kubectl-convert"

# user might not have sudo rights - just install to $HOME/bin if they want it in /usr/local/bin they can sudo this script
#
#sudo=""
#[ "$EUID" = 0 ] || sudo=sudo
#
#$sudo install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert

if [ "$EUID" = 0 ]; then
    timestamp "Installing to /usr/local/bin"
    echo
    # on Mac breaks as expects a numeric UID
    #install -v -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert
    install -v -m 0755 kubectl-convert /usr/local/bin/kubectl-convert
else
    timestamp "Installing to $HOME/bin"
    echo
    mkdir -p -v ~/bin
    install -v -m 0755 kubectl-convert ~/bin/kubectl-convert
fi
echo

timestamp "Checking the plugin is installed properly by calling it through kubectl"
echo

kubectl convert --help

rm kubectl-convert
rm kubectl-convert.sha256
