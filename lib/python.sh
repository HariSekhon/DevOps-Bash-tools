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
. "$srcdir_bash_tools_python/ci.sh"

# shellcheck disable=SC1090
. "$srcdir_bash_tools_python/os.sh"

# shellcheck disable=SC1090
#. "$srcdir_bash_tools_python/../.bash.d/python.sh"

# set to true for debugging CI builds like Semaphore CI's weird Python environment on Mac where it defaults to /usr/bin/python (2.7)
# but /usr/local/opt/python/libexec/bin/pip (python 3.7) or /usr/local/bin/pip3 (python 3.8), causing library installation vs runtime import mismatches
# (now checked for further below to catch early and highlight the root cause)
#if [ -n "${DEBUG:-}" ]; then
if false; then
    if is_semaphore_ci; then
        echo
        echo "Python and Pip installations:"
        # very slow, pushes build past 1 hour
        for x in python python2 python3 pip pip2 pip3; do
            find / -type f -name "$x" -exec ls -l {} \; -o \
                   -type l -name "$x" -exec ls -l {} \; 2>/dev/null || :
        done
        echo
        echo
    fi
fi

# shellcheck disable=SC2034
python="${PYTHON:-python}"

#if command -v pip >/dev/null 2>&1; then
    python="$(command -v "$python" || command -v "python3" || command -v "python2" || :)"
    # shellcheck disable=SC2181
    if [ $? != 0 ]; then
        echo "ERROR: 'command -v $python' failed" >&2
        exit 1
    fi
#fi

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

install_pip_manually(){
    if is_mac; then
        brew install openssl || :
        brew_prefix="$(brew --prefix)"
        export OPENSSL_INCLUDE="$brew_prefix/opt/openssl/include"
        export OPENSSL_LIB="$brew_prefix/opt/openssl/lib"
    fi
    curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python get-pip.py
}

# Needed on Semaphore Mac builds and also Ubuntu 20.04 LTS
#
#if is_semaphore_ci; then
#    echo "Semaphore CI detected, installing manually to avoid non-SSL version"
#    install_pip_manually
if ! command -v "$pip" >/dev/null 2>&1; then
    echo "pip not installed, trying to install manually..."
    install_pip_manually
fi

pip="$(command -v "$pip")"

if [[ "$pip" =~ pip3$ ]] &&
   "$python" -V 2>&1 | grep -q 'Python 2'; then
#   [ -L "$python" ] &&
#    python3="$(command -v python3 2>/dev/null || :)"
#    if [ -n "$python3" ]; then
#        echo "Symlinking python to python3 to match pip3:"
#        ln -sfv "$python3" "$python"
#    fi
    if command -v python3 &>/dev/null; then
        python="$(command -v python3)"
    fi
elif [[ "$python" =~ python3 ]] &&
    "$pip" -V 2>&1 | grep -qi 'python[ /]2'; then
    if command -v pip3 &>/dev/null; then
        pip="$(command -v pip3)"
    fi
fi

set +eo pipefail
# split steps for easier CI debugging in DEBUG mode
python_version="$("$python" -V 2>&1)"
python_version="$(echo "$python_version" | grep -Eom1 '[[:digit:]]+\.[[:digit:]]+')"
export python_major_version="${python_version%%.*}"
pip_python_version="$("$pip" -V 2>&1)"
pip_python_version="$(echo "$pip_python_version" | grep -Eom1 '\(python [[:digit:]]+\.[[:digit:]]+\)' | sed 's/(python[[:space:]]*//; s/)//')"
export pip_python_major_version="${pip_python_version%%.*}"
set -eo pipefail

if [ -n "${python_version:-}" ] &&
   [ -n "${pip_python_version:-}" ]; then
    if [ "$python_version" != "$pip_python_version" ]; then
        echo "Python major version '$python_version' != Pip major version '$pip_python_version' !!"
        echo
        echo "python = $python"
        echo "pip    = $pip"
        echo
        echo "Python PyPI modules will not be installed to the correct site-packages and will lead to import failures later on"
        echo
        echo "Fix your \$PATH or \$PYTHON / \$PIP to be aligned to the same installation"
        exit 1
    fi
fi

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
