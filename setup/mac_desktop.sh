#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-16 10:33:03 +0100 (Wed, 16 Oct 2019)
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

echo "Install XCode CLI tools"
xcode-select --install || :  # ignore if already installed

run(){
    echo "Running $srcdir/$1"
    QUICK=1 "$srcdir/$1"
    echo
    echo
    echo "================================================================================"
}

echo
"$srcdir/shell_link.sh"

# homebrew script must be first
install_scripts="
install_homebrew.sh
install_ansible.sh
install_diff-so-fancy.sh
install_gcloud_sdk.sh
install_minikube.sh
install_minishift.sh
install_sdkman.sh
install_sdkman_all_sdks.sh
install_terraform.sh
install_vundle.sh
"
# don't use this much any more
#install_parquet-tools.sh
# Legacy CI
#install_travis.sh

for x in $install_scripts; do
    run "$x"
done
if [[ "$USER" =~ hari|sekhon ]]; then
    run install_github_ssh_key.sh
fi
