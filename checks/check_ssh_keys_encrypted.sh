#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 - 2008 (forked from .bashrc)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Checks SSH protocol v2 keys

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

section "SSH Keys encrypted check"

for arg in "$@"; do
    # shellcheck disable=SC2119
    case "$arg" in
        -*)  usage
             ;;
    esac
done

check_bin openssl

errors=0
check_ssh_keys_encrypted(){
    echo "checking keys:"
    echo
    for key in "${@:-~/.ssh/id_rsa}"; do
        printf "%s" "$key => "
        if openssl rsa -noout -passin pass:none -in "$key" 2>/dev/null; then
            echo "WARNING: your SSH Key '$key' is unprotected. Encrypt it and use SSH agent"
            errors=1
        else
            echo "OK"
        fi
    done
}

check_ssh_keys_encrypted "$@"

if [ $errors = 1 ]; then
    exit 1
fi

echo
hr
echo
