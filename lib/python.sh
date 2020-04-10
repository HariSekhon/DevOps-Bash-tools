#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-03 13:14:22 +0100 (Fri, 03 Apr 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir_bash_tools_python="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir_bash_tools_python/os.sh"

# shellcheck disable=SC2034
python="${PYTHON:-python}"

if is_mac; then
    # try to find pip in brew installed Python versions since it is
    # not in /System/Library/Frameworks/Python.framework/Versions/2.7/bin
    for dir in /usr/local/Cellar/python*; do
        if [ -d "$dir" ]; then
            export PATH="$PATH:/$dir/bin"
        fi
    done
fi

if [ -n "${PIP:-}" ]; then
    pip="$PIP"
else
    if type -P pip &>/dev/null; then
        pip=pip
    elif type -P pip2 &>/dev/null; then
        echo "pip not found, falling back to pip2" >&2
        pip=pip2
    else
        pip=pip
    fi
fi

inside_virtualenv(){
    if [ -n "${VIRTUAL_ENV:-}" ] ||
       #[ -n "${PYENV_ROOT:-}" ] ||
       [ -n "${CODESHIP_VIRTUALENV:-}" ] ||
       [ -n "${CONDA_DEFAULT_ENV:-}" ]; then
        return 0
    elif [ -n "${PYENV_ROOT:-}" ]; then
        if type -P "$python" | grep -q "$PYENV_ROOT" &&
           type -P "$pip" | grep -q "$PYENV_ROOT"; then
            return 0
        fi
    # Codeship path when using virtualenv
    elif type -P "$python" | grep -Eqi '/\.pyenv/|/shims/'; then
        return 0
    elif type -P "$pip" | grep -Eqi '/\.pyenv/|/shims/'; then
        return 0
    fi
    return 1
}
