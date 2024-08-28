#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-28 21:07:22 +0200 (Wed, 28 Aug 2024)
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
Decompiles a Java jar

Unpacks it in /tmp, finds the Main-Class from the META-INF/MANIFEST.MF
and runs the Java decompiler JD GUI on its main .class file

Uses adjacent script ./jd_gui.sh
which uses ../install/download_jd_gui_jar.sh if the JD GUI jar is not already available

Require Java to already be installed and in the \$PATH
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<jar>"

help_usage "$@"

min_args 1 "$@"

jar="$1"

readlink(){
    if is_mac; then
        command greadlink "$@"
    else
        command readlink "$@"
    fi
}

if ! [[ "$jar" =~ \.jar$ ]]; then
    die "ERROR: arg given is not a JAR file: $jar"
fi

if ! [[ -f "$jar" ]]; then
    die "ERROR: jar file not found: $jar"
fi

jar="$(readlink -f "$jar")"
if is_mac; then
    jar="${jar/\/private\/tmp/\/tmp}"
fi

if [ "$jar" != "/tmp/${jar##*/}" ]; then
    timestamp "Copying JAR to /tmp:"
    echo >&2
    unalias cp >&/dev/null || :
    cp -fv "$jar" /tmp/
    echo >&2
fi

cd /tmp/

jar="${jar##*/}"

timestamp "Unpacking JAR"
#echo >&2
tar zxf "$jar"
#echo >&2
echo >&2

timestamp "Determining main class"
main_class="$(awk '/Main-Class:/{print $2}' META-INF/MANIFEST.MF)"
echo >&2
if is_blank "$main_class"; then
    die "ERROR: failed to find Main-Class from unpacked jar's META-INF/MANIFEST.MF"
fi
timestamp "Determined main class to be: $main_class"
echo >&2

main_class_file="${main_class//./\/}"

timestamp "Running decompiler on main class: $main_class_file"
echo >&2
"$srcdir/jd_gui.sh" "$main_class_file"
