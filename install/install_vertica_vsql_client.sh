#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-09-10 01:19:15 +0200 (Tue, 10 Sep 2024)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://kubernetes.io/docs/tasks/tools/install-kubectl/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Vertica VSQL Client on Linux x86_64

Installs vqsql binary to /usr/local/bin/ or \$HOME/bin/ depending on your permissions

Offical Documentation:

    https://docs.vertica.com/23.4.x/en/connecting-to/using-vsql/installing-vsql-client/

Download URLs:

    https://www.vertica.com/download/vertica/client-drivers/
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#min_args 1 "$@"

#version="24.2.0"
version="${1:-latest}"

# Required by the vsql binary
#
# Invalid locale: run the "locale" command and check for warnings
#export LANG="end_US.UTF-8"
export LC_ALL="C.UTF-8"

libxcrypt_package=""
if type -P rpm &>/dev/null; then
    libxcrypt_package="libxcrypt-compat"
elif type -P apt-get &>/dev/null; then
    libxcrypt_package="libxcrypt-compat"
    # or
    #libxcypt_package="libcrypt1"
else
    timestamp "WARNING: unknown package manager, not RPM or Apt based, not downloading the libxcrypt dependency"
    echo
fi

if [ -n "$libxcrypt_package" ]; then
    timestamp "Installing libxcrypt dependency"
    echo
    "$srcdir/../packages/install_packages.sh" "$libxcrypt_package"
    echo
fi

downloads_url="https://www.vertica.com/download/vertica/client-drivers/"

# ERE format for grep -E
tar_url_regex="https://www.vertica.com/client_drivers/[[:digit:].x-]+/[[:digit:].-]+/vertica-client-[[:digit:].-]+.x86_64.tar.gz"

# Should match these:
#
# https://www.vertica.com/client_drivers/24.2.x/24.2.0-1/vertica-client-24.2.0-1.x86_64.tar.gz
# https://www.vertica.com/client_drivers/24.1.x/24.1.0-0/vertica-client-24.1.0-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/23.4.x/23.4.0-0/vertica-client-23.4.0-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/23.3.x/23.3.0-0/vertica-client-23.3.0-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/12.0.x/12.0.4-0/vertica-client-12.0.4-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/11.1.x/11.1.1-0/vertica-client-11.1.1-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/11.0.x/11.0.2-0/vertica-client-11.0.2-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/10.1.x/10.1.1-0/vertica-client-10.1.1-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/10.0.x/10.0.1-0/vertica-client-10.0.1-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/9.3.x/9.3.1-0/vertica-client-9.3.1-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/9.2.x/9.2.1-0/vertica-client-9.2.1-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/9.1.x/9.1.1-0/vertica-client-9.1.1-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/9.0.x/9.0.1-0/vertica-client-9.0.1-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/8.1.x/8.1.1-0/vertica-client-8.1.1-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/8.0.x/8.0.1/vertica-client-8.0.1-0.x86_64.tar.gz
# https://www.vertica.com/client_drivers/7.2.x/7.2.3-0/vertica-client-7.2.3-0.x86_64.tar.gz

timestamp "Fetching list of Vertica tarball download URLs from $downloads_url"
tar_urls="$(
    curl -sS "$downloads_url" |
    grep -Eo "$tar_url_regex"
)"

if [ "$version" = "latest" ]; then
    timestamp "Determining latest version from list of tarball download urls"
    download_url="$(head -n1 <<< "$tar_urls")"
    timestamp "Determined latest tarball version to be ${download_url##*/}"
else
    timestamp "Checking if requested version '$version' is available"
    download_url="$(grep "$version" <<< "$tar_urls" | head -n 1 || :)"
    if [ -z "$download_url" ]; then
        echo
        echo "ERROR: Vertica Client tarball version '$version' not found" >&2
        echo
        echo "Here are the list of available versions:"
        echo
        sed 's/.*vertica-client-//; s/-[[:digit:]]\+.x86_64.tar.gz$//' <<< "$tar_urls"
        echo
        exit 1
    fi
fi

export RUN_VERSION_OPT=1

#timestamp "Downloading from: $download_url"
"$srcdir/../packages/install_binary.sh" "$download_url" opt/vertica/bin/vsql

# automatically run by install_binary.sh when RUN_VERSION_OPT=1 is set above
#if [ -w /usr/local/bin ]; then
#    /usr/local/bin/vsql --version
#else
#    ~/bin/vsql --version
#fi

echo
echo "You may need to also set your locale, such as putting this in your \$HOME/.bashrc:"
echo
echo "    export LC_ALL=$LC_ALL"
echo
