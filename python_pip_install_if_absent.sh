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

echo "Installing Python PyPI Modules listed in file(s): $*"

opts=""
if [ -n "${TRAVIS:-}" ]; then
    echo "running in quiet mode"
    opts="-q"
fi

export LDFLAGS=""
if [ "$(uname -s)" = "Darwin" ]; then
    export LDFLAGS="-I/usr/local/opt/openssl/include -L/usr/local/opt/openssl/lib"
fi

pip_modules="$(cat "$@" | sed 's/#.*//;/^[[:space:]]*$$/d' | sort -u)"

SUDO=""
if [ $EUID != 0 ] &&
   [ -z "${VIRTUAL_ENV:-}" ] &&
   [ -z "${CONDA_DEFAULT_ENV:-}" ]; then
    SUDO=sudo
fi

for pip_module in $pip_modules; do
    python_module="$("$srcdir/python_module_to_import_name.sh" <<< "$pip_module")"

    # pip module often pull in urllib3 which result in errors like the following so ignore it
    #:
    # Cannot uninstall 'urllib3'. It is a distutils installed project and thus we cannot accurately determine which files belong to it which would lead to only a partial uninstall.
    #
    #echo "checking if python module '$python_module' is installed"
    if ! python -c "import $python_module" &>/dev/null; then
        echo "python module '$python_module' not installed"
        $SUDO "${PIP:-pip}" install $opts --ignore-installed urllib3 "$pip_module"
    fi
done
