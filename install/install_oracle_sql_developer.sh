#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-11 07:19:37 +0300 (Fri, 11 Oct 2024)
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
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Oracle SQL Developer IDE
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

max_args 1 "$@"

version="${1:-23.1.1.345.2114}"

export OS_DARWIN=macos
export ARCH_ARM64=aarch64

os="$(get_os)"
arch="$(get_arch)"

if type -P yum &>/dev/null; then
    yum install -y "https://download.oracle.com/otn_software/java/sqldeveloper/sqldeveloper-$version.noarch.rpm"
elif is_mac; then
    url="https://download.oracle.com/otn_software/java/sqldeveloper/sqldeveloper-$version-$os-$arch.app.zip"
    zip="${url##*/}"
    wget -c "$url"
    unzip -o "$zip"
    sql_developer="SQLDeveloper.app"
    if ! [ -d "$sql_developer" ]; then
        die "Failed to find expected extracted directory: $sql_developer"
    fi
    mv -iv "$sql_developer" /Applications
    open -a "$sql_developer"
else
    die "Unsupport OS - not Mac or RHEL based"
fi
