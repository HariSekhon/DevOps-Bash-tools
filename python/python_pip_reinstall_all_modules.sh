#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-29 17:57:47 +0000 (Sat, 29 Feb 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Reinstalls all Python Pip modules which is often the fix for the python startup error
#
# "Illegal instruction: 4"
#
# which is often caused by some corrupted module or incompatability vs local CPU architecture
# which recompiling often solves

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "${PIP:-}" ]; then
    pip="$PIP"
else
    pip=pip
    if ! type -P "pip" &>/dev/null; then
        echo "pip not found, falling back to pip2"
        pip=pip2
    fi
fi
opts="${PIP_OPTS:-}"

# want splitting
# shellcheck disable=SC2086
"$pip" $opts freeze | PIP_OPTS="--force-reinstall" xargs "$srcdir/python_pip_install.sh"
