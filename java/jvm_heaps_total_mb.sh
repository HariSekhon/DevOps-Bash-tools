#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-01 16:54:55 +0000 (Fri, 01 Feb 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Calculates the total combined RAM in MB allocated to all Java heap sizes on all JVM processes running on the local machine
#
# Requires recent version of GNU coreutils to be installed for correct MB conversions (you might need to 'brew upgrade coreutils' on Mac)
#
# You should account for at least ~20% overhead on top of this to account for non-heap Java RAM usage eg. off-heap allocations, JIT optimizations, JNI code, GC (especially G1) etc...
#
# Sun JDK 8, OpenJDK 11 and IBM JDK all treat the last -Xmx on the command line as the actual one, so we are going with that
#
# You can check this is true on your specific implementation like so:
#
# java -version; java -Xmx1G -XX:+PrintFlagsFinal -Xmx2G 2>/dev/null | grep MaxHeapSize

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if [ "$(uname -s)" = Darwin ]; then
    # numfmt seems to only work on capitalized unit suffixes
    numfmt(){ gnumfmt "$@"; }
fi

# picks up other things like Adobe crash reporter with lots of java related env vars - which is wrong, we only care about CLI args to java procs
# shellcheck disable=SC2009
#pgrep -l -f java |
ps -ef |
grep java |
grep -v -e '[[:space:][:alpha:]]grep[[:space:]]' -e 'sed[[:space:]]' |
sed 's/.*[[:space:]]-Xmx/-Xmx/' |
grep --color=no -o -- '-Xmx[^[:space:]]*' |
sed 's/-Xmx//' |
numfmt --from=iec |
awk '{sum += $1} END {print sum}' |
numfmt --to-unit=Mi # newers versions (eg. 8.30) need Mi for correct unit conversion,
                    # but older versions (eg. 8.23) crash when given Mi as target unit
                    # eg.  'Abort trap: 6' - if this happens to you, 'brew upgrade coreutils' to resolve it
