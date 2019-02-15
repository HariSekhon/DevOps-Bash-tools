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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if [ $# == 0 ]; then
    echo "usage: ${0##*/} <filename> <filename> ..."
    exit 1
fi

echo "Installing any Python PyPI Modules not already present"

pip_modules="$(sed 's/#.*//;/^[[:space:]]*$$/d' "$@")"

SUDO=""
if [ $EUID != 0 -a -z "${VIRTUAL_ENV:-}" -a -z "${CONDA_DEFAULT_ENV:-}" ]; then
    SUDO=sudo
fi

for pip_module in $pip_modules; do
    python_module="$(sed '
        s/[>=].*$//;
        s/beautifulsoup4/bs4/;
        s/requests-kerberos/requests_kerberos/;
        s/PyYAML/yaml/;
    ' <<< "$pip_module")"
    python -c "import $python_module" || ${SUDO} ${PIP:-pip} install --ignore-installed urllib3 "$pip_module"
done
