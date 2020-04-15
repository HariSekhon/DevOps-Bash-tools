#!/bin/sh
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
srcdir_bash_tools_python="$(cd "$(dirname "$0")" && pwd -P)"

# shellcheck disable=SC1090
. "$srcdir_bash_tools_python/ci.sh"

# shellcheck disable=SC1090
. "$srcdir_bash_tools_python/os.sh"

# shellcheck disable=SC1090
#. "$srcdir_bash_tools_python/../.bash.d/python.sh"

if is_semaphore_ci; then
    set -x
fi

# shellcheck disable=SC2034
python="${PYTHON:-python}"
python="$(command -v "$python")"

if [ -n "${PIP:-}" ]; then
    pip="$PIP"
else
    pip="$(command -v pip 2>/dev/null)" ||
    pip="$(command -v pip2 2>/dev/null)" ||
    pip="$(command -v pip3 2>/dev/null)" || :
    if [ -z "$pip" ]; then
        echo "pip not found, falling back to trying just 'pip'" >&2
        pip=pip
    fi
fi

if is_mac &&
   ! command -v "$pip" >/dev/null 2>&1; then
    echo "pip not installed, trying to install manually..."
    brew install openssl || :
    curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    brew_prefix="$(brew --prefix)"
    export OPENSSL_INCLUDE="$brew_prefix/opt/openssl/include"
    export OPENSSL_LIB="$brew_prefix/opt/openssl/lib"
    python get-pip.py
fi

pip="$(command -v "$pip")"

inside_virtualenv(){
    if [ -n "${VIRTUAL_ENV:-}" ] ||
       #[ -n "${PYENV_ROOT:-}" ] ||
       [ -n "${CODESHIP_VIRTUALENV:-}" ] ||
       [ -n "${CONDA_DEFAULT_ENV:-}" ]; then
        return 0
    elif [ -n "${PYENV_ROOT:-}" ]; then
        if command -v "$python" | grep -q "$PYENV_ROOT" &&
           command -v "$pip" | grep -q "$PYENV_ROOT"; then
            return 0
        fi
    # GitHub Actions Python versions
    elif command -v "$python" | grep -Eqi '/hostedtoolcache/'; then
    #or
    #elif command -v "$pip" | grep -Eqi '/hostedtoolcache/'; then
        return 0
    # CircleCI uses /opt/circleci/.pyenv/shims/python
    # Codeship path when using virtualenv
    elif command -v "$python" | grep -Eqi '/\.pyenv/|/shims/'; then
        return 0
    elif command -v "$pip" | grep -Eqi '/\.pyenv/|/shims/'; then
        return 0
    fi
    return 1
}
