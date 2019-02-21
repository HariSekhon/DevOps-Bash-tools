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

echo "Installing any Python PyPI Modules not already present"

pip_modules="$(cat "$@" | sed 's/#.*//;/^[[:space:]]*$$/d' | sort -u)"

SUDO=""
if [ $EUID != 0 -a -z "${VIRTUAL_ENV:-}" -a -z "${CONDA_DEFAULT_ENV:-}" ]; then
    SUDO=sudo
fi

for pip_module in $pip_modules; do
    python_module="$("$srcdir/python_pip_normalize_module_names.sh" <<< "$pip_module")"

    # pip module often pull in urllib3 which result in errors like the following so ignore it
    #:
    # Cannot uninstall 'urllib3'. It is a distutils installed project and thus we cannot accurately determine which files belong to it which would lead to only a partial uninstall.
    #
    python -c "import $python_module" || $SUDO ${PIP:-pip} install --ignore-installed urllib3 "$pip_module"
done
