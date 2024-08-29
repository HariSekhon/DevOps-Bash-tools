#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-28 21:02:58 +0200 (Wed, 28 Aug 2024)
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
Wrapper to download and run the CFR command line java decompiler

Examples:

    ${0##*/} Main.class > Main.java

    ${0##*/} myapp.jar

    ${0##*/} myapp.jar --outputdir ./myapp-java-code/
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<jar_or_java.class>"

# let see the help from tool instead
#help_usage "$@"

min_args 1 "$@"

cfr_jar="$srcdir/cfr.jar"

if ! [ -f "$cfr_jar" ]; then
    pushd "$srcdir"
    ../install/download_cfr_jar.sh
    timestamp
    echo -n "Symlinking: " >&2
    ln -sv cfr-*.jar "${cfr_jar##*/}"
    popd
fi

java -jar "$cfr_jar" "$@"
