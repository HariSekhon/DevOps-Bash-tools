#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 13:56:24 +0000 (Fri, 15 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Avoids trying to install / upgrade pip modules that have been installed with system packages to avoid errors like the following:
#
# Cannot uninstall 'beautifulsoup4'. It is a distutils installed project and thus we cannot accurately determine which files belong to it which would lead to only a partial uninstall.

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

usage(){
    echo "Installs Python PyPI modules using Pip only if they are not installed by testing for their imports and skipping any that are already installed"
    echo
    echo "Leverages adjacent python_pip_install.sh which takes in to account library paths, virtual envs etc"
    echo
    echo "Takes a list of python module names as arguments or .txt files containing lists of modules (one per line)"
    echo
    echo "usage: ${0##*} <list_of_modules>"
    echo
    exit 3
}

pip_modules=""
for x in "$@"; do
    if [ -f "$x" ]; then
        echo "adding pip modules from file:  $x"
        pip_modules="$pip_modules $(sed 's/#.*//;/^[[:space:]]*$$/d' "$x")"
        echo
    else
        pip_modules="$pip_modules $x"
    fi
    pip_modules="$(tr ' ' ' \n' <<< "$pip_modules" | sort -u | tr '\n' ' ')"
done

for x in "$@"; do
    case "$1" in
        -*) usage
            ;;
    esac
done

if [ -z "$pip_modules" ]; then
    usage
fi

echo "Installing Python PyPI Modules that are not already installed"
echo

for pip_module in $pip_modules; do
    python_module="$("$srcdir/python_module_to_import_name.sh" <<< "$pip_module")"

    # pip module often pull in urllib3 which result in errors like the following so ignore it
    #:
    # Cannot uninstall 'urllib3'. It is a distutils installed project and thus we cannot accurately determine which files belong to it which would lead to only a partial uninstall.
    #
    #echo "checking if python module '$python_module' is installed"
    if python -c "import $python_module" &>/dev/null; then
        echo "python module '$python_module' already installed, skipping..."
    else
        echo "installing python module '$python_module'"
        "$srcdir/python_pip_install.sh" --ignore-installed urllib3 "$pip_module"
    fi
done
