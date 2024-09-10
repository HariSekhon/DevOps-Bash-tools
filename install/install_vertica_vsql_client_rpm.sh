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
Installs Vertica VSQL Client RPM on a Redhat-based Linux x86_64

If FIPS=true environment variable is set then downloads and installs the FIPS compliant RPM instead

Offical Documentation:

    https://docs.vertica.com/23.4.x/en/connecting-to/client-libraries/client-drivers/install-config/fips/installing-fips-client-driver-odbc-and-vsql/

Download URLs:

    https://www.vertica.com/download/vertica/client-drivers/

Tested on Rocky Linux 8, 9
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
    # already available on older Rocky Linux 8 from this package
    if ! rpm -q libxcrypt &>/dev/null; then
        libxcrypt_package="libxcrypt-compat"
    fi
else
    die "ERROR: running on a non-RPM system"
fi

if [ -n "$libxcrypt_package" ]; then
    timestamp "Installing libxcrypt dependency"
    echo
    "$srcdir/../packages/install_packages.sh" "$libxcrypt_package"
    echo
fi

downloads_url="https://www.vertica.com/download/vertica/client-drivers/"

fips=""
if [ "${FIPS:-}" = true ]; then
    fips="-fips"
fi

# ERE format for grep -E
rpm_url_regex="https://www.vertica.com/client_drivers/[[:digit:].x-]+/[[:digit:].-]+/vertica-client$fips-[[:digit:].-]+.x86_64.rpm"

# Should match either these regular RPMs:
#
# https://www.vertica.com/client_drivers/24.2.x/24.2.0-1/vertica-client-24.2.0-1.x86_64.rpm
# https://www.vertica.com/client_drivers/24.1.x/24.1.0-0/vertica-client-24.1.0-0.x86_64.rpm
# https://www.vertica.com/client_drivers/23.4.x/23.4.0-0/vertica-client-23.4.0-0.x86_64.rpm
# https://www.vertica.com/client_drivers/23.3.x/23.3.0-0/vertica-client-23.3.0-0.x86_64.rpm
# https://www.vertica.com/client_drivers/12.0.x/12.0.4-0/vertica-client-12.0.4-0.x86_64.rpm
# https://www.vertica.com/client_drivers/11.1.x/11.1.1-0/vertica-client-11.1.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/11.0.x/11.0.2-0/vertica-client-11.0.2-0.x86_64.rpm
# https://www.vertica.com/client_drivers/10.1.x/10.1.1-0/vertica-client-10.1.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/10.0.x/10.0.1-0/vertica-client-10.0.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/9.3.x/9.3.1-0/vertica-client-9.3.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/9.2.x/9.2.1-0/vertica-client-9.2.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/9.1.x/9.1.1-0/vertica-client-9.1.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/9.0.x/9.0.1-0/vertica-client-9.0.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/8.1.x/8.1.1-0/vertica-client-8.1.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/8.0.x/8.0.1/vertica-client-8.0.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/7.2.x/7.2.3-0/vertica-client-7.2.3-0.x86_64.rpm
#
# or if FIPS=true is set these RPMs:
#
# https://www.vertica.com/client_drivers/24.2.x/24.2.0-1/vertica-client-fips-24.2.0-1.x86_64.rpm
# https://www.vertica.com/client_drivers/24.1.x/24.1.0-0/vertica-client-fips-24.1.0-0.x86_64.rpm
# https://www.vertica.com/client_drivers/23.4.x/23.4.0-0/vertica-client-fips-23.4.0-0.x86_64.rpm
# https://www.vertica.com/client_drivers/23.3.x/23.3.0-0/vertica-client-fips-23.3.0-0.x86_64.rpm
# https://www.vertica.com/client_drivers/12.0.x/12.0.4-0/vertica-client-fips-12.0.4-0.x86_64.rpm
# https://www.vertica.com/client_drivers/11.1.x/11.1.1-0/vertica-client-fips-11.1.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/11.0.x/11.0.2-0/vertica-client-fips-11.0.2-0.x86_64.rpm
# https://www.vertica.com/client_drivers/10.1.x/10.1.1-0/vertica-client-fips-10.1.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/9.2.x/9.2.1-0/vertica-client-fips-9.2.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/9.1.x/9.1.1-0/vertica-client-fips-9.1.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/9.0.x/9.0.1-0/vertica-client-fips-9.0.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/8.1.x/8.1.1-0/vertica-client-fips-8.1.1-0.x86_64.rpm
# https://www.vertica.com/client_drivers/8.0.x/8.0.1/vertica-client-fips-8.0.1-0.x86_64.rpm

timestamp "Fetching list of Vertica RPM download URLs from $downloads_url"
rpm_urls="$(
    curl -sS "$downloads_url" |
    grep -Eo "$rpm_url_regex"
)"

if [ "$version" = "latest" ]; then
    timestamp "Determining latest version from list of RPM download urls"
    download_url="$(head -n1 <<< "$rpm_urls")"
    timestamp "Determined latest RPM version to be ${download_url##*/}"
else
    timestamp "Checking if requested version '$version' is available"
    download_url="$(grep "$version" <<< "$rpm_urls" | head -n 1 || :)"
    if [ -z "$download_url" ]; then
        echo
        echo "ERROR: Vertica Client RPM FIPS version '$version' not found" >&2
        echo
        echo "Here are the list of available versions:"
        echo
        sed 's/.*vertica-client-//; s/-[[:digit:]]\+.x86_64.rpm$//' <<< "$rpm_urls"
        echo
        exit 1
    fi
fi

timestamp "Installing from: $download_url"
echo

yum install -y "$download_url"
echo

/opt/vertica/bin/vsql --version

echo
echo "You may need to also set your locale, such as putting this in your \$HOME/.bashrc:"
echo
echo "    export LC_ALL=$LC_ALL"
echo
