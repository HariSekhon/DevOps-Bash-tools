#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 - 2008 (forked from .bashrc)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Checks SSH protocol v2 keys

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

for arg in "$@"; do
    case "$arg" in
        -*)  usage
             ;;
    esac
done

check_bin openssl

errors=0
check_ssh_keys_encrypted(){
    for key in "${@:-~/.ssh/id_rsa}"; do
        if openssl rsa -noout -passin pass:none -in "$key" 2>/dev/null; then
            echo "WARNING: your SSH Key '$key' is unprotected. Encrypt it and use SSH agent"
            errors=1
        fi
    done
}

check_ssh_keys_encrypted "$@"

if [ $errors = 1 ]; then
    exit 1
fi
