#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-09-16 14:09:20 +0200 (Mon, 16 Sep 2024)
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
Runs Avro Tools, downloading it if not already present

Uses ../install/download_avro_tools.sh to download the latest version if no version is present

You can call that script directory if you want to update the version

--help prints this message. For Avro Tools help use no args

Requires Java to be installed to run the avro-tools-<version>.jar
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<avro_tools_args>"

help_usage "$@"

#min_args 1 "$@"

avro_tools_jar="$(find "$srcdir" -maxdepth 1 -name 'avro-tools-*.jar' | sort -Vr | head -n 1)"

if [ -z "$avro_tools_jar" ] ||
   # incomplete download, call download again to resume it
   ! jar tf "$avro_tools_jar" &>/dev/null; then
    pushd "$srcdir" 2>/dev/null
    "$srcdir/../install/download_avro_tools.sh"
    popd "$srcdir" 2>/dev/null
fi

java -jar "$avro_tools_jar" "$@"
