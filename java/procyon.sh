#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-28 23:03:58 +0200 (Wed, 28 Aug 2024)
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
Wrapper to download and run the Procyon command line java decompiler

Examples:

    ${0##*/} Main.class > Main.java

    ${0##*/} myapp.jar
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<jar_or_java.class>"

# let see the help from tool instead
#help_usage "$@"

min_args 1 "$@"

procyon_jar="$srcdir/procyon-decompiler.jar"

if ! [ -f "$procyon_jar" ]; then
    pushd "$srcdir"
    ../install/download_procyon_jar.sh
    timestamp
    echo -n "Symlinking: " >&2
    ln -sv procyon-*.jar "${procyon_jar##*/}"
    popd
fi

java -jar "$procyon_jar" "$@"
