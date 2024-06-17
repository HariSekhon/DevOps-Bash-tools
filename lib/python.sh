#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-03 13:14:22 +0100 (Fri, 03 Apr 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir_bash_tools_python="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir_bash_tools_python/ci.sh"

# shellcheck disable=SC1090
. "$srcdir_bash_tools_python/os.sh"

# need all the paths for when Pip gets installed locally
if ! type add_PATHS &>/dev/null ; then
    # shellcheck disable=SC1090
    . "$srcdir_bash_tools_python/../.bash.d/python.sh"
fi

# set to true for debugging CI builds like Semaphore CI's weird Python environment on Mac where it defaults to /usr/bin/python (2.7)
# but /usr/local/opt/python/libexec/bin/pip (python 3.7) or /usr/local/bin/pip3 (python 3.8), causing library installation vs runtime import mismatches
# (now checked for further below to catch early and highlight the root cause)
#if [ -n "${DEBUG:-}" ]; then
#    if is_semaphore_ci; then
#        echo
#        echo "Python and Pip installations:"
#        # very slow, pushes build past 1 hour
#        for x in python python2 python3 pip pip2 pip3; do
#            find / -type f -name "$x" -exec ls -l {} \; -o \
#                   -type l -name "$x" -exec ls -l {} \; 2>/dev/null || :
#        done
#        echo
#        echo
#    fi
#fi

if [ -n "${PYTHON:-}" ]; then
    python="$PYTHON"
else
    #python="$(command -v "$python" || command -v "python3" || command -v "python2" || :)"
    # XXX: bug, on new M1 Macs command -v appears to return 'python' where it is not installed, possibly inherited, whereas we need it to fail to fall through to python3
    #python="$(command -v python 2>/dev/null || :)"
    python="$(type -P python 2>/dev/null || :)"
    python2="$(type -P python2 2>/dev/null || :)"
    python3="$(type -P python3 2>/dev/null || :)"
    if [ -z "$python" ]; then
        if [ -n "${python3:-}" ]; then
            python="$python3"
        elif [ -n "${python2:-}" ]; then
            python="$python2"
        else
            echo "ERROR: 'command -v python' failed to find python" >&2
            exit 1
        fi
    fi
fi

if [ -n "${PIP:-}" ]; then
    pip="$PIP"
else
    pip="$(command -v pip 2>/dev/null || :)"
    pip2="$(command -v pip2 2>/dev/null || :)"
    pip3="$(command -v pip3 2>/dev/null || :)"
    if [ -z "$pip" ]; then
        if [ -n "$pip3" ]; then
            pip="$pip3"
        elif [ -n "${pip2:-}" ]; then
            pip="$pip2"
        else
            echo "pip not found, falling back to trying just 'pip'" >&2
            pip=pip
        fi
    fi
fi

install_pip_manually(){
    if is_mac; then
        brew install openssl || :
        brew_prefix="$(brew --prefix)"
        export OPENSSL_INCLUDE="$brew_prefix/opt/openssl/include"
        export OPENSSL_LIB="$brew_prefix/opt/openssl/lib"
    fi
    if "$python" -V 2>&1 | grep -q '^Python 2'; then
        curl -sS https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py
    else
        curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    fi
    "$python" get-pip.py
    rm -f -- get-pip.py
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

# bad idea, programs with /usr/env/python will often call python 2 and fail to find pip modules
#if [[ "$pip" =~ pip3$ ]] &&
#   "$python" -V 2>&1 | grep -q 'Python 2'; then
#   [ -L "$python" ] &&
##    python3="$(command -v python3 2>/dev/null || :)"
##    if [ -n "$python3" ]; then
##        echo "Symlinking python to python3 to match pip3:"
##        ln -sfv "$python3" "$python"
##    fi
#    if command -v python3 &>/dev/null; then
#        python="$(command -v python3)"
#    fi
#elif [[ "$python" =~ python3 ]] &&
#    "$pip" -V 2>&1 | grep -qi 'python[ /]2'; then
#    if command -v pip3 &>/dev/null; then
#        pip="$(command -v pip3)"
#    fi
#fi

# replace with fully qualified, which aids in debugging different CI environments
pip="$(command -v "$pip")"

recursion_depth=0
check_python_pip_versions_match(){
    ((recursion_depth+=1))
    if [ $recursion_depth -gt 5 ]; then
        echo "recursing too deep in $srcdir_bash_tools_python/python.sh, non-trivial python vs pip versions mismatch!"
        exit 1
    fi
    set +eo pipefail
    # split steps for easier CI debugging in DEBUG mode
    python_version="$("$python" -V 2>&1)"
    python_version="$(<<< "$python_version" grep -Eom1 '[[:digit:]]+\.[[:digit:]]+')"
    export python_major_version="${python_version%%.*}"
    pip_python_version="$("$pip" -V 2>&1)"
    pip_python_version="$(<<< "$pip_python_version" grep -Eom1 '\(python [[:digit:]]+\.[[:digit:]]+\)' | sed 's/(python[[:space:]]*//; s/)//')"
    export pip_python_major_version="${pip_python_version%%.*}"
    set -eo pipefail

    if [ -n "${python_version:-}" ] &&
       [ -n "${pip_python_version:-}" ]; then
        if [ "$python_version" != "$pip_python_version" ]; then
            if [ "${python_version:0:1}" = 3 ] &&
               [ -n "${pip3:-}" ]; then
                pip="$pip3"
                check_python_pip_versions_match
            elif [ "${python_version:0:1}" = 2 ]; then
                if [ -n "${pip2:-}" ]; then
                    pip="$pip2"
                else
                    # python2-pip removed from Ubuntu / Alpine repos :-(
                    install_pip_manually
                    pip="$(command -v "pip")"
                fi
                check_python_pip_versions_match
            # switching to python3 will lead programs with /usr/env/python defaulting to python 2 to fail to find pip modules
            #elif [ "${python_version:0:1}" = 2 ] &&
            #     [ -n "${python3:-}" ]; then
            #    python="$python3"
            #    check_python_pip_versions_match
            else
                echo
                echo "Python major version '$python_version' != Pip major version '$pip_python_version' !!"
                echo
                echo "python = $python"
                echo "pip    = $pip"
                echo
                echo "Python PyPI modules will not be installed to the correct site-packages and will lead to import failures later on"
                echo
                echo "Fix your \$PATH or \$PYTHON / \$PIP to be aligned to the same installation"
                echo
                exit 1
            fi
        fi
    fi
}

check_python_pip_versions_match

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
    elif command -v "$python" | grep -Eqi '/\.pyenv/|/shims/|/home/'; then
        return 0
    elif command -v "$pip" | grep -Eqi '/\.pyenv/|/shims/|/home/'; then
        return 0
    fi
    return 1
}

find_python_files(){
    local startpath="${1:-.}"
    shift || :
    find "$startpath" "$@" -type f -iname '*.py' |
    sort
}
find_jython_files(){
    local startpath="${1:-.}"
    shift || :
    find "$startpath" "$@" -type f -iname '*.jy' |
    sort
}
find_python_jython_files(){
    local startpath="${1:-.}"
    shift || :
    find "$startpath" "$@" -type f -iname '*.py' -o \
                           -type f -iname '*.jy' |
    sort
}
